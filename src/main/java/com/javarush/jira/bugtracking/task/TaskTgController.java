package com.javarush.jira.bugtracking.task;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Set;

@RestController
@RequestMapping("/api/tasks/{taskId}/tags")
@RequiredArgsConstructor
public class TaskTgController {
    private final TaskService taskService;


    @GetMapping
    public ResponseEntity<Set<String>> getTags(@PathVariable long taskId) {
        return ResponseEntity.ok(taskService.getTags(taskId));
    }


    @PostMapping
    public ResponseEntity<Set<String>> addTag(
            @PathVariable long taskId,
            @RequestBody @NotBlank @Size(min = 2, max = 32) String tag) {
        return ResponseEntity.ok(taskService.addTag(taskId, tag.trim()));
    }


    @DeleteMapping("/{tag}")
    public ResponseEntity<Void> deleteTag(
            @PathVariable long taskId,
            @PathVariable @NotBlank @Size(min = 2, max = 32) String tag) {
        taskService.removeTag(taskId, tag.trim());
        return ResponseEntity.noContent().build();
    }
}
