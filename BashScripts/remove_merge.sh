#!/bin/bash
find P90 -type f -name "*_merged*" | while read -r filepath; do
	newpath="${filepath//_merged/}"
	mv "$filepath" "$newpath"
	echo "Renommé : $filepath -> $newpath"
done
