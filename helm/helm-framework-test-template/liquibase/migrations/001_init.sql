--liquibase formatted sql
--changeset helm-framework:001-init
CREATE TABLE helm_framework_smoke (id INT NOT NULL);
