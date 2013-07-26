#!/bin/sh
# NOTE: mustache templates need \ because they are not awesome.
exec erl -noshell -pa /home/pi/wpi/ebin/ /home/pi/pc/erlang/pc/ebin/ \
    /home/pi/Emysql/ebin ebin edit deps/*/ebin -boot start_sasl \
    -sname pc \
    -s greeting \
    -s reloader \
    -s test

