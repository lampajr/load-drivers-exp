#!/bin/bash

set -x trace

THREADS=${THREADS:-2}
QUARKUS_BACKLOG=${QUARKUS_BACKLOG:-"-1"}
QUARKUS_CONNECTIONS=${QUARKUS_CONNECTIONS:-"100"}
QUARKUS_IDLE_TIMEOUT=${QUARKUS_IDLE_TIMEOUT:-"30M"}

# -Dquarkus.http.limits.max-connections=${QUARKUS_CONNECTIONS}
java -Djava.net.preferIPv4Stack=true -Dquarkus.vertx.event-loops-pool-size=${THREADS} -Dquarkus.http.idle-timeout=${QUARKUS_IDLE_TIMEOUT} -Dquarkus.http.accept-backlog=${QUARKUS_BACKLOG} -Dquarkus.log.level=DEBUG -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints -jar /tmp/build-quarkus-profiling-workshop/target/hello-world-app-1.0.0-SNAPSHOT-runner.jar