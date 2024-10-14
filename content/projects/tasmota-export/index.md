---
title: "Tasmota Exporter"
description: "saving all your tasmota data"
date: 2024-10-14
type: "projects"
showHero: true
---

{{< github repo="sycrw/tasmota-export" >}}

## What?

This project aims to save and store the data like power usage, from a tasmota smart plug.

## How

It all starts with the tasmota device sending its telemetry data via a mqtt broker (in this case, mosquitto)
to a python app, which saves it into an influxdb. Python was chosen for this task, as it had the easiest to work 
with a client library for mqtt and influxdb. I chose InfluxDB over Prometheus for the sole reason, that influx db
can accumulate data via push (python sends data to influx db) instead of having to scrape it like prometheus.
This way I did not have to create a rest endpoint


## Why

The idea for this project came from the following problem:
There are many solar panels for your balcony, which you can directly plug into your home network.
The Problem with these is that most of them don't have an app or even an interface to check how much power is being produced, yet show some development over time. 
With this solution any smart plug, that can use tasmota can track this data.

Another benefit of this project is, that it is fully self-hostable with e.g., a pi.

