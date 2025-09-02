# Deprecated Parallel Features

This directory contains the parallel test infrastructure that was implemented but later deprecated due to resource constraints in the containerized environment.

## Contents

- `lib/` - Enhanced parallel infrastructure including:
  - `job-manager.sh` - Parallel job management and queuing system
  - `progress-display.sh` - Live progress monitoring and display
  - `utils.sh` - Enhanced test environment and session management
  
- `run-e2e-tests-enhanced.sh` - Enhanced parallel test runner with:
  - Parallel execution with configurable job limits
  - Session logging and monitoring
  - Resource management and cleanup
  - Progress tracking

- `.temp_bin/` - Nextflow wrapper directory for environment management

## Why Deprecated

The parallel infrastructure was working correctly but individual nextflow pipeline tests were hanging due to Java thread exhaustion in the containerized environment:

```
Failed to start thread "Unknown thread" - pthread_create failed (EAGAIN)
unable to create native thread: possibly out of memory or process/resource limits reached
```

While the parallel job management, queuing, and infrastructure worked perfectly, the underlying pipeline execution environment couldn't handle the resource demands.

## Migration

The system was moved back to simple sequential execution in `run-e2e-tests.sh` while preserving the same command interface (`./cleansumstats.sh etest`, etc.). 