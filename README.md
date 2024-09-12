# Load Generators Comparison

This repository aims to automate the execution of multiple load generators against the same server (simultaneously).

## Usage

If you want to run the complete automated test, simply run:

```bash
./scripts/run-benchmarks.sh
```

You can also skip some load generators:
```bash
ARTILLERY_ENABLED=false K6_ENABLED=false HF_ENABLED=true JMETER_ENABLED=true ./run-benchmarks.sh
```

> [!NOTE]
> You need to satisfy all [prerequisites](#prerequisites), otherwise the script might fail.

Alternatively you can simply startup the server by running:
```bash
./scripts/start-server.sh
```

And then run you own tests.

## Prerequisites

To run `run-benchmarks` script you need to ensure all load generators listed below are installed or present in your local system.

Keep in mind that you can override the executable as you prefer, see the [run-benchmarks](./scripts/run-benchmarks.sh) overridable configuration.

## Server

For the sake of simplicity, the server is a minimal Quarkus based web application.

Checkout https://github.com/franz1981/quarkus-profiling-workshop for more information.

## Load Generators

At the moment of writing these are the load generators I've been using:

### Hyperfoil

A microservice-oriented distributed benchmark framework.

Checkout https://hyperfoil.io/ for more details and how to install/download it.

### JMeter

The Apache JMeter™ application is a pure Java application designed to load test functional behavior and measure performance.

Checkout https://jmeter.apache.org/ for more details and how to install/download it.

### Artillery

Artillery is an open source load testing platform.

Checkout https://www.artillery.io/ for more details and how to install/download it.

### K6

An extensible load testing tool.

Checkout https://k6.io/open-source/ for more details and how to install/download it.