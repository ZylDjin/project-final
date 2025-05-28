package com.javarush.jira.common.error;

public class AlreadyExistsException extends AppException {
    public AlreadyExistsException(String msg) {
        super(msg);
    }
}
