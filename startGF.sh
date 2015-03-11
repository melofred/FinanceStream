#!/bin/bash
export XD_HOME=~/Downloads/spring-xd-1.1.0.RELEASE/

exec $XD_HOME/gemfire/bin/gemfire-server FinanceStream-gemfire.xml
