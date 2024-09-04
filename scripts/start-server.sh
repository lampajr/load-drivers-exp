#!/bin/bash

CURRENT_DIR=$(dirname $0)

THREADS=${THREADS:-2}

java -Dquarkus.vertx.event-loops-pool-size=${THREADS} -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints -jar $CURRENT_DIR/../quarkus-profiling-workshop/target/quarkus-app/quarkus-run.jar