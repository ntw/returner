# returner

`returner` is a bit of ruby code that automates the process of creating returns to Ingram through iPage.

BUGS:
- At this point it is necessary to ignore penalized titles.  I think I need to dig in to the page source again.
- Multithreading appears to bring up a race condition (on Ingram's end I'm pretty sure) where it may report more copies returned than inteded.  I'm investigating.
