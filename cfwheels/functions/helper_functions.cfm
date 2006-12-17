<cffunction name="model" returntype="any" access="public" output="false">
	<cfargument name="name" type="string" required="yes">

	<cfset var local = structNew()>

	<cfif application.settings.environment IS "development">

		<cfquery name="local.model_query" username="#application.database.user#" password="#application.database.pass#" datasource="#application.database.source#">
		SELECT 
		<cfif application.database.type IS "sqlserver">
			(CASE WHEN column_name IS NULL THEN '' ELSE column_name END) + '' + (CASE WHEN data_type IS NULL THEN '' ELSE data_type END) + '' + (CASE WHEN is_nullable IS NULL THEN '' ELSE is_nullable END) + '' + (CASE WHEN character_maximum_length IS NULL THEN '' ELSE CAST(character_maximum_length AS varchar) END) + '' + (CASE WHEN column_default IS NULL THEN '' ELSE column_default END) AS info
		<cfelseif application.database.type IS "mysql5">
			CONCAT((CASE WHEN column_name IS NULL THEN '' ELSE column_name END),(CASE WHEN data_type IS NULL THEN '' ELSE data_type END),(CASE WHEN is_nullable IS NULL THEN '' ELSE is_nullable END),(CASE WHEN character_maximum_length IS NULL THEN '' ELSE character_maximum_length END),(CASE WHEN column_default IS NULL THEN '' ELSE column_default END)) AS info
		</cfif>
		FROM information_schema.columns
		WHERE
		<cfif application.database.type IS "mysql5">
			table_schema = '#application.database.name#'
		<cfelseif application.database.type IS "sqlserver">
			table_catalog = '#application.database.name#'	
		</cfif>
		</cfquery>
		
		<cfif fileExists(expandPath(application.filePathTo.models & '/' & arguments.name & '.cfc'))>
			<cffile action="read" file="#expandPath(application.filePathTo.models & '/' & arguments.name & '.cfc')#" variable="local.model_file">
		<cfelse>
			<cfthrow type="cfwheels.model_missing" message="There is no model named ""#arguments.name#"" in this application." detail="Create the ""#arguments.name#.cfc"" file manually in the ""app/models"" folder (it should extend ""cfwheels.model"") or use the <a href=""#application.pathTo.generator#"">Generator</a>. If you have already created the file this problem could also occur because you are referencing it incorrectly - always use singular form when referencing a model.">
		</cfif>

		<cfset local.model_hash = hash(valueList(local.model_query.info)) & hash(local.model_file)>

	</cfif>

	<cfif (NOT structKeyExists(application.wheels.models, arguments.name)) OR (application.settings.environment IS "development" AND NOT structKeyExists(application.wheels.models, "#arguments.name#_hash")) OR (application.settings.environment IS "development" AND application.wheels.models[arguments.name & "_hash"] IS NOT local.model_hash)>
		<cflock name="model_lock" type="exclusive" timeout="5">
	        <cfif (NOT structKeyExists(application.wheels.models, arguments.name)) OR (application.settings.environment IS "development" AND NOT structKeyExists(application.wheels.models, "#arguments.name#_hash")) OR (application.settings.environment IS "development" AND application.wheels.models[arguments.name & "_hash"] IS NOT local.model_hash)>
				<cfset "application.wheels.caches.#arguments.name#" = "smart_cache_id_#dateFormat(now(), 'yyyymmdd')#_#timeFormat(now(), 'HHmmss')#_#randRange(1000,9999)#">
				<cfset "application.wheels.pools.#arguments.name#" = structNew()>
				<cfset "application.wheels.models.#arguments.name#" = createObject("component", "app.models.#arguments.name#").initModel()>
	        </cfif>
	    </cflock>
	</cfif>

	<!--- UNCOMMENT THIS WHEN MAKING CHANGES INSIDE _MODEL.CFC --->
	<cfset "application.wheels.models.#arguments.name#" = createObject("component", "app.models.#arguments.name#").initModel()>
	<cfset "application.wheels.caches.#arguments.name#" = "smart_cache_id_#dateFormat(now(), 'yyyymmdd')#_#timeFormat(now(), 'HHmmss')#_#randRange(1000,9999)#">
	

	<cfif application.settings.environment IS "development">
		<cfset "application.wheels.models.#arguments.name#_hash" = local.model_hash>
	</cfif>

	<cfreturn application.wheels.models[arguments.name]>
</cffunction>


<cffunction name="pluralize" returntype="string" access="public" output="false">
	<cfargument name="text" type="string" required="yes">
	<cfargument name="from_singularize" type="boolean" required="no" default="false">
	
	<cfset var output = arguments.text>
	<cfset var firstLetter = left(output,1)>
	
	<cfloop index="i" from="1" to="#ArrayLen(application.wheels.pluralizationRules)#">
		<cfif REFindNoCase(application.wheels.pluralizationRules[i][1], arguments.text)>
			<cfset output = REReplaceNoCase(arguments.text, application.wheels.pluralizationRules[i][1], application.wheels.pluralizationRules[i][2])>
			<cfset output = firstLetter & right(output,len(output)-1)>
			<cfbreak> 
		</cfif>
	</cfloop>
	
	<cfif NOT arguments.from_singularize AND output IS singularize(output, true)>
		<cfset output = arguments.text>
	</cfif>
	
	<cfreturn output>
</cffunction>


<cffunction name="singularize" returntype="string" access="public" output="false">
	<cfargument name="text" type="string" required="yes">
	<cfargument name="from_pluralize" type="boolean" required="no" default="false">

	<cfset var output = arguments.text>
	<cfset var firstLetter = left(output,1)>
	
	<cfloop index="i" from="1" to="#ArrayLen(application.wheels.singularizationRules)#">
		<cfif REFindNoCase(application.wheels.singularizationRules[i][1], arguments.text)>
			<cfset output = REReplaceNoCase(arguments.text, application.wheels.singularizationRules[i][1], application.wheels.singularizationRules[i][2])>
			<cfset output = firstLetter & right(output,len(output)-1)>
			<cfbreak> 
		</cfif>
	</cfloop>

	<cfif NOT arguments.from_pluralize AND output IS pluralize(output, true)>
		<cfset output = arguments.text>
	</cfif>
	
	<cfreturn output>
</cffunction>


<cffunction name="camelCase" returntype="string" access="public" output="false">
	<cfargument name="text" type="string" required="yes">

	<cfset var output = "">
	
		<cfloop list="#arguments.text#" delimiters="_" index="i">
			<cfset output = output & uCase(left(i,1)) & lCase(right(i,len(i)-1))>
		</cfloop>
		<cfset output = lCase(left(output,1)) & right(output,len(output)-1)>

	<cfreturn output>
</cffunction>


<cffunction name="unCamelCase" returntype="string" access="public" output="false">
	<cfargument name="text" type="string" required="yes">

	<cfset var output = arguments.text>
	<cfset var pos = 2>

	<cfloop condition="#reFind('[A-Z]', arguments.text, pos)# GT 0">
		<cfset pos = reFind('[A-Z]', arguments.text, pos)>
		<cfset output = insert("_", output, pos-1)>
		<cfset pos = pos + 1>
	</cfloop>
	<cfset output = lCase(output)>

	<cfreturn output>
</cffunction>