#! /bin/bash

for file in *.swift
do
	grep -vEe '.*(\/\/\/|\/\/ ###sourceLocation)' "${file}" > "${file%.swift}.cleaned.swift"
	mv "${file}" "${file}.old"
	mv "${file%.swift}.cleaned.swift" "${file}"
done

rm *.swift.old