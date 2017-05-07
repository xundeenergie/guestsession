#Gast-Zugang für Debian

Manchmal erscheint es sinnvoll, für Gäste einen Zugang am Rechner zu haben. Alle Inhalte die ein Gast abspeichert werden nach dem ausloggen wieder gelöscht. Jeder neue Login startet mit einem vollkommen frischen Profil und Home-verzeichnis.

Dieses Paket stellt auf einfache Weise so einen Gast-Zugang zur Verfügung.

##Systemvoraussetzungen
Dieser Gast-Zugang ist über systemd gelöst. Dies ermöglicht es sehr einfach den Gastzugang zu aktivieren (auch mehrere), und auch wieder zu deaktivieren.
Wenn am System btrfs als Dateisystem genützt wird, wird das Home-Verzeichnis als Btrfs-Snapshot von /etc/skelXXX angelegt. Beim Ausloggen wird der gesamte Snapshot wieder gelöscht.
In GDM erscheint der Gastzugang sofort nach dem aktivieren mittels systemd

##Aktivieren des Gastzuganges
Bei der Installation des Paketes wird automatisch ein Gastzugang aktiviert. Der Username ist "gast", das Home-Verheichnis ist /home/gast, in GDM erscheint er als "Gast".
Bei der erstmaligen Anmeldung wird das Verzeichnis /etc/skel nach /etc/skelgast dupliziert und weiter nach /home/gast. 
Zur Einrichtung muss man sich einmal als Gast anmelden, den Desktop so konfigurieren, wie man ihn dem Gast zur Verfügung stellen möchte (Alias, Shortcuts, Desktop-Icons, Favoriten, Gnome3-Erweiterungen...).
Wenn der Desktop fertig eingerichtet ist, eingeloggt bleiben und als root das gesamte /home/gast nach /etc/skelgast kopieren/synchronisieren.

Dann kann man sich als Gast wieder ausloggen.

Möchte man einen anderen Gastzugang einrichten (zusätzlich oder anstelle), so führe man folgenden Befehl aus:

    systemctl enable --now guest-session@Zweiter\\x20Zugang.service

Zweiter\\x20Zugang wird als Username zu zweiterzugang aufgelöst. Der doppelte Backslash "\\" ist für das Shell-Escaping notwendig!
Will man das Skelet-Verzeichnis für den ersten Gastuser auch für den zweiten verwenden so ist dieses zu duplizieren.
Ohne Btrfs mit

    cp -r /etc/skelgast /etc/skelzweiterzugang

mit BTRFS:

    btrfs subvolume snapshot /etc/skelgast /etc/skelzweiterzugang

Für die Anpassung des zweiten Vorlagehome-Verzeichnisses gilt das selbe wie oben beschrieben.

## Beenden aller Userprozesse
Seit einigen Versionen von logind ist es Standard, dass logind beim ausloggen (der letzten Usersession) alle noch laufenden Prozesse des Users beendet.
Dies ist eigentlich ein gutes Verhalten, da z.B. zeitgeist-datahub oder hplip-systray weiterlaufen würden und so weitere Usersessions erzeugt würden, wenn sich ein User erneut einloggt.
Werden alle außerhalb einer Session laufenden Prozesse beendet wird auch screen oder tmux beendet. Das ist ein unerwünschtes Verhalten, deshalb wird in Debian standardmäßig diese Option wieder deaktiviert.

Prinzipiell ist es sehr sinnvoll alle User-Prozesse beim ausloggen zu beenden (systemd-Standardverhalten), daher muss man es in Debian manuell aktivieren:

    editor /etc/systemd/logind.conf

    KillUserProcesses=yes


Für das Problem mit screen ist im Paket my-services eine Service-Unit für Screen, die für jene User vom Administrator aktiviert werden muss, welche screen nutzen können sollen oder wollen.

    systemctl enable --now screen@$USER.service

Soll das Debian-Standardverhalten für die User-Sessions aber beibehalten werden, so muss für eine korrekte Funktion der Guestsession aber das Beenden aller User-Prozesse für Guest explizit erlaubt werden:

In /etc/systemd/logind.conf ist noch wichtig folgende Zeile zu aktivieren:
    
    editor /etc/systemd/logind.conf
    KillOnlyUsers=gast

(das "#" am Zeilenbeginn entfernen und "gast" hinzuzufügen.)


##Deaktivieren des Gastzuganges
Soll dieser Gastzugang deaktiviert werden, so führt man folgende Befehle als root aus:

    systemctl stop guest-session@Gast.service
    systemctl disable guest-session@Gast.service

Für den Zweiten Zugang sinngemäß:

    systemctl stop guest-session@Zweiter\\x20Zugang.service
    systemctl disable guest-session@Zweiter\\x20Zugang.service

Die entsprechenden Usernamen sind noch in /etc/systemd/logind.conf aus KillOnlyUsers= zu entfernen.
Und wenn notwendig ist noch das Skelet-Vorlage-Home /etc/skel$USERNAME zu entfernen.

Die Steuerungs-Files (DropIns) für das Backup sind ebenfalls zu löschen. Siehe im Punkt "Backup"

##Backup
Wenn mkbackup-btrfs in Verwendung ist, dann kann man das Home-Verzeichnis vom Gastzugang vom Backup ausnehmen. Dies geschieht über ein Konfigurations-DropIn in /etc/mkbackup-btrfs.conf.d/
Default wird mit der Installation dieses Paketes eine Datei im genannten Verzeichnis mit dem Namen guestsession.conf mit folgendem Inhalt angelegt:

    [DEFAULT]
    ignore = +/home/gast

Damit wird der Gastzugang von allen Interval-Snapshots ausgenommen. Das "+" am Beginn veranlasst, dass /home/gast zu allfällig bestehenden Ignore-Listen hinzugefügt wird.

Soll das Home-Verzeichnis des zweiten Gastzuganges wie im Beispiel weiter oben beschrieben vom Backup mit mkbackup-btrfs ausgenommen werden, so lege man eine neue Datei als root mit dem Inhalt an:

    editor /etc/mkbackup-btrfs.conf.d/zweiterzugang.conf

    [DEFAULT]
    ignore = +/home/zweiterzugang



