<cffunction name="$yearSelectTag" returntype="string" access="public" output="false">
	<cfargument name="startYear" type="numeric" required="true">
	<cfargument name="endYear" type="numeric" required="true">
	<cfscript>
		if (Structkeyexists(arguments, "value") && Val(arguments.value))
		{
			if (arguments.value < arguments.startYear && arguments.endYear > arguments.startYear)
				arguments.startYear = arguments.value;
			else if(arguments.value < arguments.endYear && arguments.endYear < arguments.startYear)
				arguments.endYear = arguments.value;
		}
		arguments.$loopFrom = arguments.startYear;
		arguments.$loopTo = arguments.endYear;
		arguments.$type = "year";
		arguments.$step = 1;
		StructDelete(arguments, "startYear");
		StructDelete(arguments, "endYear");
	</cfscript>
	<cfreturn $yearMonthHourMinuteSecondSelectTag(argumentCollection=arguments)>
</cffunction>

<cffunction name="$monthSelectTag" returntype="string" access="public" output="false">
	<cfargument name="monthDisplay" type="string" required="true">
	<cfscript>
		arguments.$loopFrom = 1;
		arguments.$loopTo = 12;
		arguments.$type = "month";
		arguments.$step = 1;
		if (arguments.monthDisplay == "abbreviations")
			arguments.$optionNames = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec";
		else if (arguments.monthDisplay == "names")
			arguments.$optionNames = "January,February,March,April,May,June,July,August,September,October,November,December";
		StructDelete(arguments, "monthDisplay");
	</cfscript>
	<cfreturn $yearMonthHourMinuteSecondSelectTag(argumentCollection=arguments)>
</cffunction>

<cffunction name="$daySelectTag" returntype="string" access="public" output="false">
	<cfscript>
		arguments.$loopFrom = 1;
		arguments.$loopTo = 31;
		arguments.$type = "day";
		arguments.$step = 1;
	</cfscript>
	<cfreturn $yearMonthHourMinuteSecondSelectTag(argumentCollection=arguments)>
</cffunction>

<cffunction name="$hourSelectTag" returntype="string" access="public" output="false">
	<cfscript>
		arguments.$loopFrom = 0;
		arguments.$loopTo = 23;
		arguments.$type = "hour";
		arguments.$step = 1;
	</cfscript>
	<cfreturn $yearMonthHourMinuteSecondSelectTag(argumentCollection=arguments)>
</cffunction>

<cffunction name="$minuteSelectTag" returntype="string" access="public" output="false">
	<cfargument name="minuteStep" type="numeric" required="true">
	<cfscript>
		arguments.$loopFrom = 0;
		arguments.$loopTo = 59;
		arguments.$type = "minute";
		arguments.$step = arguments.minuteStep;
		StructDelete(arguments, "minuteStep");
	</cfscript>
	<cfreturn $yearMonthHourMinuteSecondSelectTag(argumentCollection=arguments)>
</cffunction>

<cffunction name="$secondSelectTag" returntype="string" access="public" output="false">
	<cfscript>
		arguments.$loopFrom = 0;
		arguments.$loopTo = 59;
		arguments.$type = "second";
		arguments.$step = 1;
	</cfscript>
	<cfreturn $yearMonthHourMinuteSecondSelectTag(argumentCollection=arguments)>
</cffunction>

<cffunction name="$dateOrTimeSelect" returntype="string" access="public" output="false">
	<cfargument name="objectName" type="any" required="true">
	<cfargument name="property" type="string" required="true">
	<cfargument name="$functionName" type="string" required="true">
	<cfscript>
		var loc = {};
		loc.name = $tagName(arguments.objectName, arguments.property);
		arguments.$id = $tagId(arguments.objectName, arguments.property);
		loc.value = $formValue(argumentCollection=arguments);
		loc.returnValue = "";
		loc.firstDone = false;
		loc.iEnd = ListLen(arguments.order);
		for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
		{
			loc.item = ListGetAt(arguments.order, loc.i);
			arguments.name = loc.name & "($" & loc.item & ")";
			if (Len(loc.value))
				if (Isdate(loc.value))
					arguments.value = Evaluate("#loc.item#(loc.value)");
				else
					arguments.value = loc.value;
			else
				arguments.value = "";
			if (loc.firstDone)
				loc.returnValue = loc.returnValue & arguments.separator;
			loc.returnValue = loc.returnValue & Evaluate("$#loc.item#SelectTag(argumentCollection=arguments)");
			loc.firstDone = true;
		}
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="$yearMonthHourMinuteSecondSelectTag" returntype="string" access="public" output="false">
	<cfargument name="name" type="string" required="true">
	<cfargument name="value" type="string" required="true">
	<cfargument name="includeBlank" type="any" required="true">
	<cfargument name="label" type="string" required="true">
	<cfargument name="labelPlacement" type="string" required="true">
	<cfargument name="prepend" type="string" required="true">
	<cfargument name="append" type="string" required="true">
	<cfargument name="prependToLabel" type="string" required="true">
	<cfargument name="appendToLabel" type="string" required="true">
	<cfargument name="errorElement" type="string" required="false" default="">
	<cfargument name="$type" type="string" required="true">
	<cfargument name="$loopFrom" type="numeric" required="true">
	<cfargument name="$loopTo" type="numeric" required="true">
	<cfargument name="$id" type="string" required="true">
	<cfargument name="$step" type="numeric" required="true">
	<cfargument name="$optionNames" type="string" required="false" default="">
	<cfscript>
		var loc = {};
		loc.optionContent = "";
		if (!Len(arguments.value) && (!IsBoolean(arguments.includeBlank) || !arguments.includeBlank))
			arguments.value = Evaluate("#arguments.$type#(Now())");
		arguments.$appendToFor = arguments.$type;
		if (StructKeyExists(arguments, "order") && ListLen(arguments.order) > 1 && ListLen(arguments.label) > 1)
			arguments.label = ListGetAt(arguments.label, ListFindNoCase(arguments.order, arguments.$type));
		loc.before = $formBeforeElement(argumentCollection=arguments);
		loc.after = $formAfterElement(argumentCollection=arguments);
		loc.content = "";
		if (!IsBoolean(arguments.includeBlank) || arguments.includeBlank)
		{
			loc.args = {};
			loc.args.value = "";
			if (!IsBoolean(arguments.includeBlank))
				loc.optionContent = arguments.includeBlank;
			loc.content = loc.content & $element(name="option", content=loc.optionContent, attributes=loc.args);
		}

		if(arguments.$loopFrom < arguments.$loopTo)
		{
			for (loc.i=arguments.$loopFrom; loc.i <= arguments.$loopTo; loc.i=loc.i+arguments.$step)
			{
				loc.args = Duplicate(arguments);
				loc.args.counter = loc.i;
				loc.args.optionContent = loc.optionContent;
				loc.content = loc.content & $yearMonthHourMinuteSecondSelectTagContent(argumentCollection=loc.args);
			}
		}
		else
		{
			for (loc.i=arguments.$loopFrom; loc.i >= arguments.$loopTo; loc.i=loc.i-arguments.$step)
			{
				loc.args = Duplicate(arguments);
				loc.args.counter = loc.i;
				loc.args.optionContent = loc.optionContent;
				loc.content = loc.content & $yearMonthHourMinuteSecondSelectTagContent(argumentCollection=loc.args);
			}
		}

		if (!StructKeyExists(arguments, "id"))
			arguments.id = arguments.$id & "-" & arguments.$type;
		loc.returnValue = loc.before & $element(name="select", skip="objectName,property,label,labelPlacement,prepend,append,prependToLabel,appendToLabel,errorElement,value,includeBlank,order,separator,startYear,endYear,monthDisplay,dateSeparator,dateOrder,timeSeparator,timeOrder,minuteStep", skipStartingWith="label", content=loc.content, attributes=arguments) & loc.after;
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="$yearMonthHourMinuteSecondSelectTagContent">
	<cfscript>
		var loc = {};
		loc.args = {};
		loc.args.value = arguments.counter;
		if (arguments.value == arguments.counter)
			loc.args.selected = "selected";
		if (Len(arguments.$optionNames))
			arguments.optionContent = ListGetAt(arguments.$optionNames, arguments.counter);
		else
			arguments.optionContent = arguments.counter;
		if (arguments.$type == "minute" || arguments.$type == "second")
			arguments.optionContent = NumberFormat(arguments.optionContent, "09");
	</cfscript>
	<cfreturn $element(name="option", content=arguments.optionContent, attributes=loc.args)>
</cffunction>