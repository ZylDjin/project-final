package com.javarush.jira.bugtracking.task;

import com.javarush.jira.bugtracking.Handlers;
import com.javarush.jira.bugtracking.UserBelong;
import com.javarush.jira.bugtracking.UserBelongRepository;
import com.javarush.jira.bugtracking.sprint.Sprint;
import com.javarush.jira.bugtracking.sprint.SprintRepository;
import com.javarush.jira.bugtracking.task.mapper.TaskExtMapper;
import com.javarush.jira.bugtracking.task.mapper.TaskFullMapper;
import com.javarush.jira.bugtracking.task.to.TaskToExt;
import com.javarush.jira.bugtracking.task.to.TaskToFull;
import com.javarush.jira.common.error.AlreadyExistsException;
import com.javarush.jira.common.error.DataConflictException;
import com.javarush.jira.common.error.NotFoundException;
import com.javarush.jira.common.util.Util;
import com.javarush.jira.login.AuthUser;
import com.javarush.jira.ref.RefType;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.Assert;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

import static com.javarush.jira.bugtracking.ObjectType.TASK;
import static com.javarush.jira.bugtracking.task.TaskUtil.fillExtraFields;
import static com.javarush.jira.bugtracking.task.TaskUtil.makeActivity;
import static com.javarush.jira.ref.ReferenceService.getRefTo;

@Service
@RequiredArgsConstructor
public class TaskService {
    static final String CANNOT_ASSIGN = "Cannot assign as %s to task with status=%s";
    static final String CANNOT_UN_ASSIGN = "Cannot unassign as %s from task with status=%s";

    private final Handlers.TaskExtHandler handler;
    private final Handlers.ActivityHandler activityHandler;
    private final TaskFullMapper fullMapper;
    private final SprintRepository sprintRepository;
    private final TaskExtMapper extMapper;
    private final UserBelongRepository userBelongRepository;

    public Duration calculateInProgressTime(Long taskId) {
        List<Activity> activities = getSortedActivities(taskId);
        Activity inProgress = findLastActivityByStatus(activities, "in_progress");
        Activity readyForReview = findLastActivityByStatus(activities, "ready_for_review");

        validateActivitiesExist(inProgress, readyForReview, "in_progress", "ready_for_review");
        return calculateDurationBetween(inProgress, readyForReview);
    }

    public Duration calculateInTestingTime(Long taskId) {
        List<Activity> activities = getSortedActivities(taskId);
        Activity readyForReview = findLastActivityByStatus(activities, "ready_for_review");
        Activity done = findLastActivityByStatus(activities, "done");

        validateActivitiesExist(readyForReview, done, "ready_for_review", "done");
        return calculateDurationBetween(readyForReview, done);
    }

    private List<Activity> getSortedActivities(Long taskId) {
        return activityHandler.getRepository().findAllByTaskIdOrderByUpdatedDesc(taskId);
    }

    private Activity findLastActivityByStatus(List<Activity> activities, String targetStatus) {
        return activities.stream()
                .filter(a -> targetStatus.equalsIgnoreCase(a.getStatusCode()))
                .reduce((first, second) -> second)
                .orElse(null);
    }

    private void validateActivitiesExist(Activity first, Activity second, String firstName, String secondName) {
        if (first == null || second == null) {
            String missing = first == null ? firstName : secondName;
            throw new NotFoundException("Required status not found: " + missing);
        }
    }

    private Duration calculateDurationBetween(Activity start, Activity end) {
        return Duration.between(start.getUpdated(), end.getUpdated());
    }


    @Transactional
    public void changeStatus(long taskId, String statusCode) {
        Assert.notNull(statusCode, "statusCode must not be null");
        Task task = handler.getRepository().getExisted(taskId);
        if (!statusCode.equals(task.getStatusCode())) {
            task.checkAndSetStatusCode(statusCode);
            Activity statusChangedActivity = new Activity(null, taskId, AuthUser.authId());
            statusChangedActivity.setStatusCode(statusCode);
            activityHandler.create(statusChangedActivity);
            String userType = getRefTo(RefType.TASK_STATUS, statusCode).getAux(1);
            if (userType != null) {
                handler.createUserBelong(taskId, TASK, AuthUser.authId(), userType);
            }
        }
    }

    @Transactional
    public void changeSprint(long taskId, Long sprintId) {
        Task task = handler.getRepository().getExisted(taskId);
        if (task.getParentId() != null) {
            throw new DataConflictException("Can't change subtask sprint");
        }
        if (sprintId != null) {
            Sprint sprint = sprintRepository.getExisted(sprintId);
            if (sprint.getProjectId() != task.getProjectId()) {
                throw new DataConflictException("Target sprint must belong to the same project");
            }
        }
        handler.getRepository().setTaskAndSubTasksSprint(taskId, sprintId);
    }

    @Transactional
    public Task create(TaskToExt taskTo) {
        Task created = handler.createWithBelong(taskTo, TASK, "task_author");
        activityHandler.create(makeActivity(created.id(), taskTo));
        return created;
    }

    @Transactional
    public void update(TaskToExt taskTo, long id) {
        if (!taskTo.equals(get(taskTo.id()))) {
            handler.updateFromTo(taskTo, id);
            activityHandler.create(makeActivity(id, taskTo));
        }
    }

    public TaskToFull get(long id) {
        Task task = Util.checkExist(id, handler.getRepository().findFullById(id));
        TaskToFull taskToFull = fullMapper.toTo(task);
        List<Activity> activities = activityHandler.getRepository().findAllByTaskIdOrderByUpdatedDesc(id);
        fillExtraFields(taskToFull, activities);
        taskToFull.setActivityTos(activityHandler.getMapper().toToList(activities));
        return taskToFull;
    }

    public TaskToExt getNewWithSprint(long sprintId) {
        Sprint sprint = sprintRepository.getExisted(sprintId);
        Task newTask = new Task();
        newTask.setSprintId(sprintId);
        newTask.setProjectId(sprint.getProjectId());
        return extMapper.toTo(newTask);
    }

    public TaskToExt getNewWithProject(long projectId) {
        Task newTask = new Task();
        newTask.setProjectId(projectId);
        return extMapper.toTo(newTask);
    }

    public TaskToExt getNewWithParent(long parentId) {
        Task parent = handler.getRepository().getExisted(parentId);
        Task newTask = new Task();
        newTask.setParentId(parentId);
        newTask.setSprintId(parent.getSprintId());
        newTask.setProjectId(parent.getProjectId());
        return extMapper.toTo(newTask);
    }

    public void assign(long id, String userType, long userId) {
        checkAssignmentActionPossible(id, userType, true);
        handler.createUserBelong(id, TASK, userId, userType);
    }

    @Transactional
    public void unAssign(long id, String userType, long userId) {
        checkAssignmentActionPossible(id, userType, false);
        UserBelong assignment = userBelongRepository.findActiveAssignment(id, TASK, userId, userType)
                .orElseThrow(() -> new NotFoundException(String
                        .format("Not found assignment with userType=%s for task {%d} for user {%d}", userType, id, userId)));
        assignment.setEndpoint(LocalDateTime.now());
    }

    private void checkAssignmentActionPossible(long id, String userType, boolean assign) {
        Assert.notNull(userType, "userType must not be null");
        Task task = handler.getRepository().getExisted(id);
        String possibleUserType = getRefTo(RefType.TASK_STATUS, task.getStatusCode()).getAux(1);
        if (!userType.equals(possibleUserType)) {
            throw new DataConflictException(String.format(assign ? CANNOT_ASSIGN : CANNOT_UN_ASSIGN, userType, task.getStatusCode()));
        }
    }

    @Transactional(readOnly = true)
    public Set<String> getTags(long taskId) {
        return handler.getRepository().findById(taskId)
                .map(Task::getTags)
                .orElseThrow(() -> new NotFoundException("Task not found"));
    }

    @Transactional
    public Set<String> addTag(long taskId, String tag) {
        Task task = handler.getRepository().findById(taskId)
                .orElseThrow(() -> new NotFoundException("Task not found"));
        if (task.getTags().contains(tag)) {
            throw new AlreadyExistsException("Tag already exists");
        }
        task.getTags().add(tag);
        return handler.getRepository().save(task).getTags();
    }

    @Transactional
    public void removeTag(long taskId, String tag) {
        Task task = handler.getRepository().findById(taskId)
                .orElseThrow(() -> new NotFoundException("Task not found"));
        if (!task.getTags().remove(tag)) {
            throw new NotFoundException("Tag not found");
        }
        handler.getRepository().save(task);
    }
}