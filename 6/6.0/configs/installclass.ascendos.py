#
# ascendos.py
#
# This file was copied from the Scientific Linux project.
#
# Copyright (C) 2010  Red Hat, Inc.  All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

import os
import logging
log = logging.getLogger("anaconda")

from rhel import InstallClass as RHELInstallClass

from constants import *

class InstallClass(RHELInstallClass):
    # make sure the translation data is read from product.img tree
    if os.path.isdir("/tmp/product/locale"):
        import gettext
        gettext.bindtextdomain("comps", localedir="/tmp/product/locale")
        _ = lambda x: gettext.ldgettext("comps", x)
        N_ = lambda x: x
    # name has underscore used for mnemonics, strip if you dont need it
    id = "ascendos"
    sortPriority = 90000
    name = N_("Ascendos")
    _description = N_("Please pick the type of install for %s. "
                     "You can optionally select a different set of software "
                     "now.")
    hidden = 0

    tasks = [(N_("Desktop"),
              ["base", "core", "debugging",
               "directory-client", "java-platform", "network-file-system-client",
               "server-platform",
               "fonts", "print-client", 
               "basic-desktop", "desktop-debugging", "desktop-platform",
               "general-desktop", "graphical-admin-tools", "input-methods",
               "legacy-x", "x11", "internet-browser", "internet-applications", "office-suite",
               "remote-desktop-clients"]),
              (N_("Minimal Desktop"),
              ["base", "core",
               "directory-client", "network-file-system-client",
               "fonts", "print-client",
               "basic-desktop", "desktop-platform",
               "input-methods",
               "legacy-x", "x11", "internet-browser", "ice-desktop",
               "remote-desktop-clients"]),
             (N_("Basic Server"),
              ["base", "console-internet", "core", "debugging",
               "directory-client", "hardware-monitoring", "java-platform", 
               "large-systems", "network-file-system-client",
               "performance", "perl-runtime", "server-platform"]),
             (N_("Database Server"),
              ["base", "console-internet", "core", "debugging",
               "directory-client", "hardware-monitoring", "java-platform", 
               "large-systems", "network-file-system-client",
               "performance", "perl-runtime", "server-platform",
               "mysql-client", "mysql", "postgresql-client", "postgresql",
               "system-admin-tools"]),
             (N_("Web Server"),
              ["base", "console-internet", "core", "debugging",
               "directory-client", "java-platform", 
               "network-file-system-client",
               "performance", "perl-runtime", "server-platform",
               "web-server", "web-servlet", "php", "turbogears",
               "mysql-client", "postgresql-client"]),
             (N_("Virtual Host"),
              ["base", "console-internet", "core", "debugging",
               "directory-client", "hardware-monitoring", "java-platform", 
               "large-systems", "network-file-system-client",
               "performance", "perl-runtime", "server-platform",
               "virtualization", "virtualization-client",
               "virtualization-platform"]),
             (N_("Software Development Workstation"),
              ["base", "core", "debugging",
               "directory-client", "java-platform", "network-file-system-client",
               "performance", "perl-runtime", "server-platform",
               "fonts", "print-client",
               "basic-desktop", "desktop-debugging", "desktop-platform",
               "general-desktop", "graphical-admin-tools", "input-methods",
               "legacy-x", "x11", "internet-browser", "graphics", "emacs", "tex",
               "remote-desktop-clients", "virtualization", "virtualization-client",
               "virtualization-platform",
               "desktop-platform-devel", "development", "eclipse",
               "server-platform-devel", "technical-writing",
               "additional-devel"]),
             (N_("Web Development Workstation"),
              ["base", "core", "debugging",
               "directory-client", "java-platform", "network-file-system-client",
               "perl-runtime", "server-platform",
               "fonts", "print-client", 
               "basic-desktop", "desktop-debugging", "desktop-platform",
               "general-desktop", "graphical-admin-tools", "input-methods",
               "legacy-x", "x11", "internet-browser", "internet-applications", "graphics", "emacs",
               "desktop-platform-devel", "development", "eclipse",
               "server-platform-devel",
               "web-server", "web-servlet", "php", "turbogears",
               "mysql-client", "postgresql-client",
               "additional-devel",
               "remote-desktop-clients"]),
             (N_("Minimal"),
              ["core"])]


    def productMatches(self, oldprod):
        log.debug("oldprod is %s ",oldprod)

        if oldprod is None:
            return False

        if oldprod.startswith(productName):
            return True

        productUpgrades = {
            "Red Hat Enterprise Linux AS": ("Red Hat Linux Advanced Server", ),
            "Red Hat Enterprise Linux WS": ("Red Hat Linux Advanced Workstation",),
            # FIXME: this probably shouldn't be in a release...
            "Red Hat Enterprise Linux": ("Red Hat Linux Advanced Server",
                                         "Red Hat Linux Advanced Workstation",
                                         "Red Hat Enterprise Linux AS",
                                         "Red Hat Enterprise Linux ES",
                                         "Red Hat Enterprise Linux WS"),
            "Red Hat Enterprise Linux Server": ("Red Hat Enterprise Linux AS",
                                                "Red Hat Enterprise Linux ES",
                                                "Red Hat Enterprise Linux WS",
                                                "Red Hat Enterprise Linux"),
            "Red Hat Enterprise Linux Client": ("Red Hat Enterprise Linux WS",
                                                "Red Hat Enterprise Linux Desktop",
                                                "Red Hat Enterprise Linux"),
            "Ascendos": ("Ascendos"),
        }

        if productUpgrades.has_key(productName):
            acceptable = productUpgrades[productName]
        else:
            acceptable = ()

        for p in acceptable:
            if oldprod.startswith(p):
                return True

        return False

    def __init__(self):
        RHELInstallClass.__init__(self)

    def _get_description(self):
        return gettext.ldgettext("comps", self._description) % self._descriptionFields
    description = property(_get_description)
