# Agent Guidelines

This document provides essential guidelines and instructions for agents working on this repository.

## Workflow: GitFlow

All contributors and agents must follow the **GitFlow** way of work.
- Detailed guideline: [GitFlow Way of Work](https://cloudopsworks.co/resources/gitflow-way-of-work/)

### Working Process
1.  **Checkout & Branching:** After checking out the repository, always start working from the `develop` branch.
2.  **Initialization:** Before starting any development, initialize the project by running:
    ```bash
    make code/init
    ```

## Protected Files and Directories

The following files and directories are managed by the platform and **MUST NOT** be modified at all:
- `Makefile` (root directory)
- `.github/` (all contents)
- `.cloudopsworks/labeler.yml`
- `.cloudopsworks/Makefile`
- `.cloudopsworks/LICENSE`

## Application Re-initialization

If you need to cleanup the sample code and initialize a new Flutter application targeting Android and iOS, follow these steps:

### 1. Cleanup Sample Code
Remove the `lib` directory and the `test` directory (except for basic smoke tests if needed):
```bash
rm -rf lib/ test/
```

### 2. Initialize New Flutter App
From the root of the project, run the `flutter create` command to re-initialize the project for Android and iOS. 
**Note:** Use the `--force` flag with caution if there are files you wish to preserve, otherwise use the project's organization and name.

```bash
flutter create --org com.cloudopsworks --project-name <your_project_name> --platforms android,ios .
```

### 3. Re-apply Initial Configurations
After running `flutter create`, ensure that the project is still correctly initialized with the platform-specific tools:
```bash
make code/init
```

Ensure that `@.gitignore` is updated to include the necessary Flutter SDK and iOS targeting exclusions.
