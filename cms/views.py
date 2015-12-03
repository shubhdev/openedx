from django.shortcuts import render,get_object_or_404
from django.http import HttpResponse,HttpResponseRedirect
from django.template import RequestContext, loader
from django.http import Http404
from django.core.urlresolvers import reverse
from django.views import generic
import os
from os import listdir
from os.path import isfile, join
import os.path
import json
#Parse the JSON log for KeyLogger data 


def parseLogs(filePath):
	f=open(filePath,'r')	
	for line in f:
		j=json.loads(line)
		if j['event_type']=='KeyLogger':
			result+=line
	return result

def get_logs(request):
	fileDir='/edx/var/log/tracking/'
	result=''
	onlyfiles = [f for f in listdir(fileDir) if isfile(join(fileDir, f))]
	for x in onlyfiles:
		temp_file=fileDir+x
		if(x.endswith('.log')):
			result=result+parseLogs(temp_file)
		else:
			os.system('gunzip -c '+temp_file+' '+fileDir+'temp.log')
			result=result+parseLogs(fileDir+'temp.log')
			os.system('rm -f '+fileDir+'temp.log')

	return HttpResponse(result)