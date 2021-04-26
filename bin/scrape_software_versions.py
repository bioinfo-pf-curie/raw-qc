#!/usr/bin/env python
from collections import OrderedDict
import re
import os

regexes = {
    'Raw-qc': ['v_rawqc.txt', r"(\S+)"],
    'Nextflow': ['v_nextflow.txt', r"(\S+)"],
    'FastQC': ['v_fastqc.txt', r"FastQC v(\S+)"],
    'TrimGalore': ['v_trimgalore.txt', r"version (\S+)"],
    'Fastp': ['v_fastp.txt', r"fastp (\S+)"],
    'Atropos': ['v_atropos.txt', r"Atropos version (\S+)"],
    'MultiQC': ['v_multiqc.txt', r"multiqc, version (\S+)"],
}

results = OrderedDict({
    key: '<span style="color:#999999;\">N/A</span>'
    for key in regexes.keys()})

# Search each file using its regex
for k, v in regexes.items():
    if os.path.exists(v[0]):
        with open(v[0]) as x:
            versions = x.read()
            match = re.search(v[1], versions)
            if match:
                results[k] = "v{}".format(match.group(1))

# Remove software set to false in results
for k in results:
    if not results[k]:
        del(results[k])

# Dump to YAML
yaml_output = '''
id: 'software_versions'
section_name: 'Software versions'
section_href: 'https://github.com/nf-core/sarek'
plot_type: 'html'
description: 'are collected at run time from the software output.'
data: |
    <dl class="dl-horizontal">
'''

for k, v in results.items():
    yaml_output += "        <dt>{}</dt><dd><samp>{}</samp></dd>".format(k, v)
print(yaml_output + "    </dl>")

# Write out regexes as csv file:
with open('software_versions.csv', 'w') as f:
    for k, v in results.items():
        f.write("{}\t{}\n".format(k, v))
