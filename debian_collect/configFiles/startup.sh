#!/bin/bash
wg-quick up mullvad
curl https://am.i.mullvad.net/connected
firefox -headless ""
