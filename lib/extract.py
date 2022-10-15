#! /usr/bin/env python 
import re, sys
the_file = sys.argv[1]    
with open( the_file, "r") as f:
    lines = f.readlines()
    text = "\n".join(lines)
#print(text)
start_tag="^# Performance"
end_tag="^#"
pattern="(?s){}.*?{}".format(start_tag, end_tag)
print(pattern)
result=re.findall(pattern, text)
print(result)
