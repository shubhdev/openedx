from django.shortcuts import render,get_object_or_404
from django.http import HttpResponse,HttpResponseRedirect
from django.template import RequestContext, loader
from django.http import Http404
from django.core.urlresolvers import reverse
from django.views import generic
import os
import os.path
import json
#Parse the JSON log for KeyLogger data 
def parseLogs(filePath):
	f=open(filePath,'r')
	result=''
	for line in f:
		j=json.loads(line)
		if j['event_type']=='KeyLogger':
			result+=line


	return result

def get_logs(request):
	filePath='/edx/var/log/tracking/tracking.log'
	if os.path.isfile(filePath) and os.access(filePath,os.R_OK):
		return HttpResponse(parseLogs(filePath))
	else:
		return HttpResponse('tracking does not')

