#ifndef LOCATE_PLUGINS_H
#define LOCATE_PLUGINS_H

// Replace the incorrect PLUGINPATH supplied by the Makefile
#undef PLUGINPATH
#define PLUGINPATH locate_plugins("../libexec/bcftools")

const char *locate_plugins(const char *relative_location);
#endif  /* LOCATE_PLUGINS_H */
