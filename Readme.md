## Pure Dart implementation of Git



## Background / History

This library represents my coming a full circle. Back in Feb-May 2014 I built git-crx - a Chrome app Git client based on the fantastic git-html5 library by Ryan Ackley. My goal then was to build a "gui" Git client that could run on Chromebooks. In the end I didn't have enough time and later on when Android support came to some Chromebooks, I switched by foxus and time to working on SGit nee MGit, a rather more full featured android git client which I took over maintaince for but again has fallen a bit into disrepair as I have not had time to maintain it as well as I would have liked.

Now, in late 2018, I've become more and more impressed with the great improvement in productivity that Flutter has brought to Android app development. Which brought me round to wanting to build a substantial app using it and again the thought of building a Android Git client, but I was not so inclined to write a platform channel to connect to either jgit being Java would be Android only and stuck at a very old version due to newer version of the library being based on Java 7 APis unavailable until very recent versions of Android or to try to reate a binding to C library libgit, which would have its own challenges.

So googling around for something Dart based, I was reminded of the port to Dart of Ryans library that was done for the now defunct Chrome DevEditor tool.

Hence this library, which is a continuation of that initial port, modernised for Dart 2 and primarily for use with Flutter apps.