lxqube
======

Containerize your desktop using LXC. Inspired by Qubes OS.

This is a work in progress.

Goals (not comprehensive):

* Keep it lightweight. Rely on Linux kernel-based containerization features instead of virtualization.
* Make it easy to create, run, destroy sandboxes without root daemons running in the background.
* Create template system - sandboxes get reset back to a default state when restarted
* Support sandboxed GUI applications via Xephyr and Openbox
