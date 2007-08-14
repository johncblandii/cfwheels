<cffunction name="initModel" returntype="any" access="public" output="true">
	<cfset var local = structNew()>

	<cfset variables.model_name = listLast(getMetaData(this).name, ".")>
	<cfset variables.pluralized_model_name = pluralize(variables.model_name)>

	<cfif NOT structKeyExists(variables, "table_name")>
		<cfset variables.table_name = variables.pluralized_model_name>
	</cfif>
	<cfif NOT structKeyExists(variables, "primary_key")>
		<cfset variables.primary_key = "id">
	</cfif>

	<!--- <cfset variables.functions = "">
	<cfif NOT structKeyExists(variables, "associations")>
		<cfset variables.associations = "">
	<cfelse>
		<cfset local.functions.has_one = "object,setObject,hasObject,buildObject,createObject">
		<cfset local.functions.has_many = "objects,addObject,deleteObject,clearObjects,hasObjects,objectCount,findOneObject,findAllObjects,findObjectByID,buildObject,createObject">
		<cfset local.functions.belongs_to = "object,setObject,hasObject,buildObject,createObject">
		<cfset local.functions.has_and_belongs_to_many = "objects,addObject,deleteObject,clearObjects,hasObjects,objectCount,findOneObject,findAllObjects,findObjectByID">
		<cfloop collection="#variables.associations#" item="local.i">
			<cfif variables.associations[local.i].model_name IS "">
				<cfset variables.associations[local.i].model_name = singularize(local.i)>
			</cfif>
			<cfif variables.associations[local.i].foreign_key IS "">
				<cfif variables.associations[local.i].type IS "belongs_to">
					<cfset variables.associations[local.i].foreign_key = variables.associations[local.i].model_name & "_id">
				<cfelse>
					<cfset variables.associations[local.i].foreign_key = variables.model_name & "_id">
				</cfif>
			</cfif>
			<cfif variables.associations[local.i].type IS "has_and_belongs_to_many">
				<cfif variables.associations[local.i].join_table IS "">
					<cfif left(lCase(local.i), 1) LT left(lCase(variables.pluralized_model_name), 1)>
						<cfset variables.associations[local.i].join_table = local.i & "_" & variables.pluralized_model_name>
					<cfelse>
						<cfset variables.associations[local.i].join_table = variables.pluralized_model_name & "_" & local.i>
					</cfif>
				</cfif>
				<cfif variables.associations[local.i].association_foreign_key IS "">
					<cfset variables.associations[local.i].association_foreign_key = variables.associations[local.i].model_name & "_id">
				</cfif>
			</cfif>
			<cfset variables.associations[local.i].functions = "">
			<cfloop list="#local.functions[variables.associations[local.i].type]#" index="local.j">
				<cfset variables.functions = listAppend(variables.functions, replaceNoCase(replaceNoCase(local.j, "objects", pluralize(local.i)), "object", singularize(local.i)))>
				<cfset variables.associations[local.i].functions = listAppend(variables.associations[local.i].functions, replaceNoCase(replaceNoCase(local.j, "objects", pluralize(local.i)), "object", singularize(local.i)))>
			</cfloop>
		</cfloop>
	</cfif> --->

	<cfquery name="local.get_columns_query" datasource="ss_userlevel">
	SELECT column_name, data_type, is_nullable, character_maximum_length, column_default
	FROM information_schema.columns
	WHERE table_name = '#variables.table_name#' AND
	<cfif application.database.type IS "mysql5">
		table_schema = '#application.database.name#'
	<cfelseif application.database.type IS "sqlserver">
		table_catalog = '#application.database.name#'
	</cfif>
	</cfquery>

	<cfset variables.columns = valueList(local.get_columns_query.column_name)>
	<cfloop query="local.get_columns_query">
		<cfset "variables.column_info.#column_name#.db_sql_type" = data_type>
		<cfset "variables.column_info.#column_name#.cf_sql_type" = getCFSQLType(data_type)>
		<cfset "variables.column_info.#column_name#.cf_data_type" = getCFDataType(data_type)>
		<cfset "variables.column_info.#column_name#.nullable" = is_nullable>
		<cfset "variables.column_info.#column_name#.max_length" = character_maximum_length>
		<cfset "variables.column_info.#column_name#.default" = column_default>
	</cfloop>

	<cfreturn this>
</cffunction>


<cffunction name="initObject" returntype="any" access="public" output="false">

	<cfset var local = structNew()>

	<!--- Copy model variables --->
	<cfset variables.model_name = listLast(getMetaData(this).name, ".")>
	<cfset variables.table_name = application.wheels.models[variables.model_name].getTableName()>
	<cfset variables.primary_key = application.wheels.models[variables.model_name].getPrimaryKey()>
	<!--- <cfset variables.associations = application.wheels.models[variables.model_name].getAssociations()>
	<cfset variables.functions = application.wheels.models[variables.model_name].getFunctions()> --->
	<cfset variables.columns = application.wheels.models[variables.model_name].columns()>
	<cfset variables.column_info = duplicate(application.wheels.models[variables.model_name].getColumnInfo())>

	<!--- Point dynamic object functions to methodMissing --->
	<!--- <cfloop list="#variables.functions#" index="local.i">
		<cfset "this.#local.i#" = this.methodMissing>
	</cfloop> --->

	<!--- Create object variables --->
	<cfset this.errors = arrayNew(1)>
	<cfset this.query = queryNew("")>
	<cfset this.paginator = structNew()>
	<cfset this.recordcount = 0>
	<cfset this.recordfound = false>

	<cfreturn this>
</cffunction>


<cffunction name="reset" returntype="any" access="public" output="false">
	<cfset var i = 0>

	<cfloop list="#variables.columns#" index="i">
		<cfset structDelete(this, i)>
		<cfset structDelete(this, "#i#_confirmation")>
	</cfloop>
	<cfset this.errors = arrayNew(1)>
	<cfset this.query = queryNew("")>
	<cfset this.paginator = structNew()>
	<cfset this.recordcount = 0>
	<cfset this.recordfound = false>
</cffunction>


<cffunction name="getCFSQLType" returntype="any" access="private" output="false">
	<cfargument name="db_sql_type" type="any" required="yes">
	<cfset var result = "">
	<cfinclude template="includes/db_#application.database.type#.cfm">
	<cfreturn result>
</cffunction>


<cffunction name="getCFDataType" returntype="any" access="private" output="false">
	<cfargument name="db_sql_type" type="any" required="yes">
	<cfset var result = "">
	<cfinclude template="includes/cf_#application.database.type#.cfm">
	<cfreturn result>
</cffunction>


<!--- <cffunction name="methodMissing" returntype="any" access="public" output="false">
	<cfset var local = structNew()>

	<cftry>
		<cfthrow>
		<cfcatch>
			<cfset local.file = replaceList(replace(cfcatch.tagcontext[2].template, application.absolutePathTo.webroot, ""), ".,/,\", "_,_,_") & "_" & cfcatch.tagcontext[2].line>
			<cfif application.settings.environment IS "production" AND structKeyExists(application.wheels.method_missing_cache, local.file)>
				<!--- dynamic function arguments was found in application scope --->
				<cfset local.method_missing_cache = application.wheels.method_missing_cache[local.file]>
			<cfelse>
				<!--- Get the line in the source that the stack trace refers to --->
				<cffile action="read" file="#cfcatch.tagcontext[2].template#" variable="local.source_file">
				<cfset local.source_line = replace(listGetAt(local.source_file, cfcatch.tagcontext[2].line, chr(10)), " ", ".", "all")>
				<cfloop list="#variables.functions#" index="local.i">
					<cfif local.source_line Contains ".#local.i#(" OR local.source_line Contains " #local.i#(">
						<cfif isDefined("local.source_method")>
							<cfthrow type="cfwheels.multiple_dynamic_functions" message="You can not have more than one dynamic function on the same line." detail="Change your source code so that it only has one dynamic function per line.">
						<cfelse>
							<cfset local.source_method = local.i>
						</cfif>
					</cfif>
				</cfloop>
				<cfloop collection="#variables.associations#" item="local.i">
					<cfif listFindNoCase(variables.associations[local.i].functions, local.source_method) IS NOT 0>
						<cfset local.method_missing_cache.function_name = local.source_method>
						<cfset local.method_missing_cache.association_name = local.i>
					</cfif>
				</cfloop>
				<!--- Store arguments in application scope so we don't have to read the source code on subsequent requests --->
				<cfset "application.wheels.method_missing_cache.#local.file#" = local.method_missing_cache>
			</cfif>
		</cfcatch>
	</cftry>

	<cfset local.options = variables.associations[local.method_missing_cache.association_name]>
	<cfif local.options.type IS "belongs_to">
		<cfset local.where = "#model(local.options.model_name).getPrimaryKey()# = #this[local.options.foreign_key]#">
	<cfelse>
		<cfset local.where = "#local.options.foreign_key# = #this[variables.primary_key]#">
	</cfif>
	<cfif local.options.where IS NOT "">
		<cfset local.where = "(#local.where#) AND (#local.options.where#)">
	</cfif>
	<cfif local.options.order IS NOT "">
		<cfset local.order = local.options.order>
	<cfelse>
		<cfset local.order = "">
	</cfif>

	<cfif local.options.type IS "has_one">
		<cfif local.method_missing_cache.function_name Contains "set">
			<cfset local.args[local.options.foreign_key] = this[variables.primary_key]>
			<cfreturn arguments[listFirst(structKeyList(arguments))].update(local.args)>
		<cfelseif local.method_missing_cache.function_name Contains "has">
			<cfreturn model(local.options.model_name).count(where=local.where) IS NOT 0>
		<cfelseif local.method_missing_cache.function_name Contains "build">
			<cfloop collection="#arguments#" item="local.i">
				<cfif isStruct(arguments[local.i])>
					<cfset local.args.attributes = arguments[local.i]>
				<cfelse>
					<cfset local.args[local.i] = arguments[local.i]>
				</cfif>
			</cfloop>
			<cfset local.args[local.options.foreign_key] = this[variables.primary_key]>
			<cfreturn model(local.options.model_name).new(argumentCollection=local.args)>
		<cfelseif local.method_missing_cache.function_name Contains "create">
			<cfloop collection="#arguments#" item="local.i">
				<cfif isStruct(arguments[local.i])>
					<cfset local.args.attributes = arguments[local.i]>
				<cfelse>
					<cfset local.args[local.i] = arguments[local.i]>
				</cfif>
			</cfloop>
			<cfset local.args[local.options.foreign_key] = this[variables.primary_key]>
			<cfreturn model(local.options.model_name).create(argumentCollection=local.args)>
		<cfelse>
			<cfreturn model(local.options.model_name).findOne(where=local.where, order=local.order)>
		</cfif>
	<cfelseif local.options.type IS "has_many">
		<cfif local.method_missing_cache.function_name Contains "add">
			<cfset local.args[local.options.foreign_key] = this[variables.primary_key]>
			<cfreturn arguments[listFirst(structKeyList(arguments))].update(local.args)>
		<cfelseif local.method_missing_cache.function_name Contains "delete">
			<cfset local.args[local.options.foreign_key] = "">
			<cfreturn arguments[listFirst(structKeyList(arguments))].update(local.args)>
		<cfelseif local.method_missing_cache.function_name Contains "clear">
			<cfquery name="local.clear_query" datasource="ss_master">
			UPDATE #model(local.options.model_name).getTableName()#
			SET #model(local.options.model_name).getTableName()#.#local.options.foreign_key# = NULL
			WHERE #local.where#
			</cfquery>
			<cfreturn true>
		<cfelseif local.method_missing_cache.function_name Contains "has">
			<cfreturn model(local.options.model_name).count(where=local.where) IS NOT 0>
		<cfelseif local.method_missing_cache.function_name Contains "count">
			<cfif structKeyExists(arguments, "where")>
				<cfset arguments.where = "#local.where# AND (#arguments.where#)">
			<cfelse>
				<cfset arguments.where = local.where>
			</cfif>
			<cfreturn model(local.options.model_name).count(argumentCollection=arguments)>
		<cfelseif local.method_missing_cache.function_name Contains "findOne">
			<cfif structKeyExists(arguments, "where")>
				<cfset arguments.where = "#local.where# AND (#arguments.where#)">
			<cfelse>
				<cfset arguments.where = local.where>
			</cfif>
			<cfif local.options.order IS NOT "" AND structKeyExists(arguments, "order")>
				<cfset arguments.order = "#local.options.order#, #arguments.order#">
			<cfelseif local.options.order IS NOT "" AND NOT structKeyExists(arguments, "order")>
				<cfset arguments.order = local.options.order>
			</cfif>
			<cfreturn model(local.options.model_name).findOne(argumentCollection=arguments)>
		<cfelseif local.method_missing_cache.function_name Contains "findAll">
			<cfif structKeyExists(arguments, "where")>
				<cfset arguments.where = "#local.where# AND (#arguments.where#)">
			<cfelse>
				<cfset arguments.where = local.where>
			</cfif>
			<cfif local.order IS NOT "" AND structKeyExists(arguments, "order")>
				<cfset arguments.order = "#local.order#, #arguments.order#">
			<cfelseif local.order IS NOT "" AND NOT structKeyExists(arguments, "order")>
				<cfset arguments.order = local.order>
			</cfif>
			<cfreturn model(local.options.model_name).findAll(argumentCollection=arguments)>
		<cfelseif local.method_missing_cache.function_name Contains "ByID">
			<cfset arguments.where = "(#local.where#) AND (#model(local.options.model_name).getPrimaryKey()# = #arguments[listFirst(structKeyList(arguments))]#)">
			<cfreturn model(local.options.model_name).findOne(argumentCollection=arguments)>
		<cfelseif local.method_missing_cache.function_name Contains "build">
			<cfloop collection="#arguments#" item="local.i">
				<cfif isStruct(arguments[local.i])>
					<cfset local.args.attributes = arguments[local.i]>
				<cfelse>
					<cfset local.args[local.i] = arguments[local.i]>
				</cfif>
			</cfloop>
			<cfset local.args[local.options.foreign_key] = this[variables.primary_key]>
			<cfreturn model(local.options.model_name).new(argumentCollection=local.args)>
		<cfelseif local.method_missing_cache.function_name Contains "create">
			<cfloop collection="#arguments#" item="local.i">
				<cfif isStruct(arguments[local.i])>
					<cfset local.args.attributes = arguments[local.i]>
				<cfelse>
					<cfset local.args[local.i] = arguments[local.i]>
				</cfif>
			</cfloop>
			<cfset local.args[local.options.foreign_key] = this[variables.primary_key]>
			<cfreturn model(local.options.model_name).create(argumentCollection=local.args)>
		<cfelse>
			<cfreturn model(local.options.model_name).findAll(where=local.where, order=local.order)>
		</cfif>
	<cfelseif local.options.type IS "belongs_to">
		<cfif local.method_missing_cache.function_name Contains "set">
			<cfset local.args[model(local.options.model_name).getPrimaryKey()] = this[local.options.foreign_key]>
			<cfreturn arguments[listFirst(structKeyList(arguments))].update(local.args)>
		<cfelseif local.method_missing_cache.function_name Contains "has">
			<cfreturn model(local.options.model_name).count(where=local.where) IS NOT 0>
		<cfelseif local.method_missing_cache.function_name Contains "build">
			<cfloop collection="#arguments#" item="local.i">
				<cfif isStruct(arguments[local.i])>
					<cfset local.args.attributes = arguments[local.i]>
				<cfelse>
					<cfset local.args[local.i] = arguments[local.i]>
				</cfif>
			</cfloop>
			<cfset local.args[model(local.options.model_name).getPrimaryKey()] = this[local.options.foreign_key]>
			<cfreturn model(local.options.model_name).new(argumentCollection=local.args)>
		<cfelseif local.method_missing_cache.function_name Contains "create">
			<cfloop collection="#arguments#" item="local.i">
				<cfif isStruct(arguments[local.i])>
					<cfset local.args.attributes = arguments[local.i]>
				<cfelse>
					<cfset local.args[local.i] = arguments[local.i]>
				</cfif>
			</cfloop>
			<cfset local.args[model(local.options.model_name).getPrimaryKey()] = this[local.options.foreign_key]>
			<cfreturn model(local.options.model_name).create(argumentCollection=local.args)>
		<cfelse>
			<cfreturn model(local.options.model_name).findAll(where=local.where, order=local.order)>
		</cfif>
	<cfelseif local.options.type IS "has_and_belongs_to_many">
		<cfif local.method_missing_cache.function_name Contains "add">
		<cfelseif local.method_missing_cache.function_name Contains "delete">
		<cfelseif local.method_missing_cache.function_name Contains "clear">
		<cfelseif local.method_missing_cache.function_name Contains "has">
		<cfelseif local.method_missing_cache.function_name Contains "count">
		<cfelseif local.method_missing_cache.function_name Contains "findOne">
		<cfelseif local.method_missing_cache.function_name Contains "findAll">
		<cfelseif local.method_missing_cache.function_name Contains "ByID">
		<cfelse>
		</cfif>
	</cfif>

</cffunction>


<cffunction name="hasOne" returntype="any" access="public" output="false">
	<cfargument name="name" type="any" required="yes">
	<cfargument name="model_name" type="any" required="no" default="">
	<cfargument name="foreign_key" type="any" required="no" default="">
	<cfargument name="where" type="any" required="no" default="">
	<cfargument name="order" type="any" required="no" default="">
	<cfset "variables.associations.#arguments.name#.type" = "has_one">
	<cfset "variables.associations.#arguments.name#.model_name" = arguments.model_name>
	<cfset "variables.associations.#arguments.name#.foreign_key" = arguments.foreign_key>
	<cfset "variables.associations.#arguments.name#.where" = arguments.where>
	<cfset "variables.associations.#arguments.name#.order" = arguments.order>
</cffunction>


<cffunction name="hasMany" returntype="any" access="public" output="false">
	<cfargument name="name" type="any" required="yes">
	<cfargument name="model_name" type="any" required="no" default="">
	<cfargument name="foreign_key" type="any" required="no" default="">
	<cfargument name="where" type="any" required="no" default="">
	<cfargument name="order" type="any" required="no" default="">
	<cfset "variables.associations.#arguments.name#.type" = "has_many">
	<cfset "variables.associations.#arguments.name#.model_name" = arguments.model_name>
	<cfset "variables.associations.#arguments.name#.foreign_key" = arguments.foreign_key>
	<cfset "variables.associations.#arguments.name#.where" = arguments.where>
	<cfset "variables.associations.#arguments.name#.order" = arguments.order>
</cffunction>


<cffunction name="belongsTo" returntype="any" access="public" output="false">
	<cfargument name="name" type="any" required="yes">
	<cfargument name="model_name" type="any" required="no" default="">
	<cfargument name="foreign_key" type="any" required="no" default="">
	<cfargument name="where" type="any" required="no" default="">
	<cfargument name="order" type="any" required="no" default="">
	<cfset "variables.associations.#arguments.name#.type" = "belongs_to">
	<cfset "variables.associations.#arguments.name#.model_name" = arguments.model_name>
	<cfset "variables.associations.#arguments.name#.foreign_key" = arguments.foreign_key>
	<cfset "variables.associations.#arguments.name#.where" = arguments.where>
	<cfset "variables.associations.#arguments.name#.order" = arguments.order>
</cffunction>


<cffunction name="hasAndBelongsToMany" returntype="any" access="public" output="false">
	<cfargument name="name" type="any" required="yes">
	<cfargument name="model_name" type="any" required="no" default="">
	<cfargument name="foreign_key" type="any" required="no" default="">
	<cfargument name="where" type="any" required="no" default="">
	<cfargument name="order" type="any" required="no" default="">
	<cfset "variables.associations.#arguments.name#.type" = "has_and_belongs_to_many">
	<cfset "variables.associations.#arguments.name#.model_name" = arguments.model_name>
	<cfset "variables.associations.#arguments.name#.foreign_key" = arguments.foreign_key>
	<cfset "variables.associations.#arguments.name#.where" = arguments.where>
	<cfset "variables.associations.#arguments.name#.order" = arguments.order>
	<cfset "variables.associations.#arguments.name#.join_table" = arguments.join_table>
	<cfset "variables.associations..#arguments.name#.association_foreign_key" = arguments.association_foreign_key>
</cffunction>


<cffunction name="getAssociations" returntype="any" access="public" output="false">

	<cfreturn variables.associations>
</cffunction>


<cffunction name="getFunctions" returntype="any" access="public" output="false">

	<cfreturn variables.functions>
</cffunction> --->


<cffunction name="setTableName" returntype="any" access="public" output="false">
	<cfargument name="name" type="any" required="yes">
	<cfset variables.table_name = arguments.name>
</cffunction>


<cffunction name="setPrimaryKey" returntype="any" access="public" output="false">
	<cfargument name="name" type="any" required="yes">
	<cfset variables.primary_key = arguments.name>
</cffunction>


<cffunction name="getModelName" returntype="any" access="public" output="false">

	<cfreturn variables.model_name>
</cffunction>


<cffunction name="getTableName" returntype="any" access="public" output="false">

	<cfreturn variables.table_name>
</cffunction>


<cffunction name="getPrimaryKey" returntype="any" access="public" output="false">

	<cfreturn variables.primary_key>
</cffunction>


<cffunction name="columns" returntype="any" access="public" output="false">

	<cfreturn variables.columns>
</cffunction>


<cffunction name="getColumnInfo" returntype="any" access="public" output="false">

	<cfreturn variables.column_info>
</cffunction>


<cffunction name="new" returntype="any" access="public" output="false">
	<cfargument name="attributes" type="any" required="no" default="#structNew()#">
	<cfset var local = structNew()>

	<cfloop collection="#arguments#" item="local.i">
		<cfif local.i IS NOT "attributes">
			<cfset arguments.attributes[local.i] = arguments[local.i]>
		</cfif>
	</cfloop>

	<cfreturn newObject(arguments.attributes)>
</cffunction>


<cffunction name="create" returntype="any" access="public" output="false">
	<cfargument name="attributes" type="any" required="no" default="#structNew()#">
	<cfset var local = structNew()>

	<cfset local.new_object = new(argumentCollection=arguments)>
	<cfset local.new_object.save()>

	<cfreturn local.new_object>
</cffunction>


<cffunction name="getObject" returntype="any" access="private" output="false">
	<cfargument name="model_name" type="any" required="yes">

	<cfset var local = structNew()>

	<cfif application.settings.environment IS "production">
		<!--- Find a vacant object in pool (lock code so that another thread can not get the same object before it has been set to 'is_taken') --->
		<cflock name="pool_lock_for_#arguments.model_name#" type="exclusive" timeout="30">
			<cfset local.vacant_objects = structFindValue(application.wheels.pools[arguments.model_name], "is_vacant", "one")>
			<cfif arrayLen(local.vacant_objects) IS NOT 0>
				<!--- Create a reference to the object in the pool and reset all instance specific data in the object so it can be re-used --->
				<cfset local.UUID = listFirst(local.vacant_objects[1].path, ".")>
				<cfset local.new_object = application.wheels.pools[arguments.model_name][local.UUID].object>
				<cfset local.new_object.reset()>
			<cfelse>
				<!--- Create a new object since no vacant ones were found in the pool --->
				<cfset local.UUID = createUUID()>
				<cfset local.new_object = createObject("component", "app.models.#arguments.model_name#").initObject()>
				<cfset application.wheels.pools[arguments.model_name][local.UUID] = structNew()>
				<cfset application.wheels.pools[arguments.model_name][local.UUID].object = local.new_object>
			</cfif>
			<!--- Set object to taken and add object's UUID to a list in the request scope so it can be set to vacant again on request end --->
			<cfset application.wheels.pools[arguments.model_name][local.UUID].status = "is_taken">
			<cfset request.wheels.taken_objects = listAppend(request.wheels.taken_objects, local.UUID)>
		</cflock>
	<cfelse>
		<cfset local.new_object = createObject("component", "app.models.#arguments.model_name#").initObject()>
	</cfif>

	<cfreturn local.new_object>
</cffunction>


<cffunction name="newObject" returntype="any" access="private" output="false">
	<cfargument name="value_collection" type="any" required="yes">

	<cfset var i = "">
	<cfset var new_object = "">

	<cfset new_object = getObject(variables.model_name)>

	<cfif isQuery(arguments.value_collection) AND arguments.value_collection.recordcount GT 0>
		<cfset new_object.query = arguments.value_collection>
		<cfset new_object.recordfound = true>
		<cfset new_object.recordcount = arguments.value_collection.recordcount>
		<cfif arguments.value_collection.recordcount IS 1>
			<cfloop list="#arguments.value_collection.columnlist#" index="i">
				<cfset new_object[replaceNoCase(i, (variables.model_name & "_"), "")] = arguments.value_collection[i][1]>
			</cfloop>
		</cfif>
	<cfelseif isStruct(arguments.value_collection)>
		<cfset new_object.query = queryNew(structKeyList(arguments.value_collection))>
		<cfset queryAddRow(new_object.query, 1)>
		<cfloop collection="#arguments.value_collection#" item="i">
			<cfset querySetCell(new_object.query, i, arguments.value_collection[i])>
		</cfloop>
		<cfloop collection="#arguments.value_collection#" item="i">
			<cfset new_object[i] = arguments.value_collection[i]>
		</cfloop>
	</cfif>

	<cfreturn new_object>
</cffunction>


<cffunction name="save" returntype="any" access="public" output="false">

	<cfset clearErrors()>
	<cfif valid()>
		<cfif isDefined("beforeValidation") AND NOT beforeValidation()>
			<cfreturn false>
		</cfif>
		<cfif isNewRecord()>
			<cfset validateOnCreate()>
			<cfif isDefined("afterValidationOnCreate") AND NOT afterValidationOnCreate()>
				<cfreturn false>
			</cfif>
		<cfelse>
			<cfset validateOnUpdate()>
			<cfif isDefined("afterValidationOnUpdate") AND NOT afterValidationOnUpdate()>
				<cfreturn false>
			</cfif>
		</cfif>
		<cfset validate()>
		<cfif isDefined("afterValidation") AND NOT afterValidation()>
			<cfreturn false>
		</cfif>
		<cfif isDefined("beforeSave") AND NOT beforeSave()>
			<cfreturn false>
		</cfif>
		<cfif isNewRecord()>
			<cfif isDefined("beforeCreate") AND NOT beforeCreate()>
				<cfreturn false>
			</cfif>
			<cfif NOT insertRecord()>
				<cfreturn false>
			</cfif>
			<cfset expireCache()>
			<cfif isDefined("afterCreate") AND NOT afterCreate()>
				<cfreturn false>
			</cfif>
		<cfelse>
			<cfif isDefined("beforeUpdate") AND NOT beforeUpdate()>
				<cfreturn false>
			</cfif>
			<cfif NOT updateRecord()>
				<cfreturn false>
			</cfif>
			<cfset expireCache()>
			<cfif isDefined("afterUpdate") AND NOT afterUpdate()>
				<cfreturn false>
			</cfif>
		</cfif>
		<cfif isDefined("afterSave") AND NOT afterSave()>
			<cfreturn false>
		</cfif>
	<cfelse>
		<cfreturn false>
	</cfif>

	<cfreturn true>
</cffunction>


<cffunction name="isNewRecord" returntype="any" access="public" output="false">
	<cfif structKeyExists(this, variables.primary_key) AND this[variables.primary_key] GT 0>
		<cfreturn false>
	<cfelse>
		<cfreturn true>
	</cfif>
</cffunction>


<cffunction name="insertRecord" returntype="any" access="private" output="false">
	<cfset var insert_columns = "">
	<cfset var insert_query = "">
	<cfset var get_id_query = "">
	<cfset var pos = 0>
	<cfset var i = "">

	<cfif listFindNoCase(variables.columns, "created_at") IS NOT 0>
		<cfset this.created_at = createODBCDateTime(now())>
	</cfif>

	<cfif listFindNoCase(variables.columns, "created_on")>
		<cfset this.created_on = createODBCDate(now())>
	</cfif>

	<cfloop list="#variables.columns#" index="i">
		<cfif structKeyExists(this, i) AND i IS NOT variables.primary_key>
			<cfset insert_columns = listAppend(insert_columns, i)>
		</cfif>
	</cfloop>

	<cfquery name="insert_query" datasource="ss_master">
	INSERT INTO	#variables.table_name#(#insert_columns#)
	VALUES (
	<cfset pos = 0>
	<cfloop list="#insert_columns#" index="i">
		<cfset pos = pos + 1>
		<cfqueryparam cfsqltype="#variables.column_info[i].cf_sql_type#" value="#this[i]#" null="#this[i] IS ''#">
		<cfif listLen(insert_columns) GT pos>
			,
		</cfif>
	</cfloop>
	)
	</cfquery>
	<cfquery name="get_id_query" datasource="ss_userlevel">
	SELECT
	<cfif application.database.type IS "sqlserver">
		@@IDENTITY AS last_id
	<cfelseif application.database.type IS "mysql5">
		LAST_INSERT_ID() AS last_id
	</cfif>
	</cfquery>
	<cfset this[variables.primary_key] = get_id_query.last_id>

	<!--- If the database sets any defaults, set them here if they're not already defined --->
	<cfloop list="#insert_columns#" index="i">
		<cfif NOT structKeyExists(this, i) AND variables.column_info[i].default IS NOT "">
			<cfset this[i] = replaceList(variables.column_info[i].default, "',(,)", ",,")>
		</cfif>
	</cfloop>

	<cfreturn true>
</cffunction>


<cffunction name="updateRecord" returntype="any" access="private" output="false">
	<cfset var update_columns = "">
	<cfset var update_query = "">
	<cfset var get_id_query = "">
	<cfset var pos = 0>
	<cfset var i = "">

	<cfif listFindNoCase(variables.columns, "updated_at") IS NOT 0>
		<cfset this.updated_at = createODBCDateTime(now())>
	</cfif>

	<cfif listFindNoCase(variables.columns, "updated_on")>
		<cfset this.updated_on = createODBCDate(now())>
	</cfif>

	<cfloop list="#variables.columns#" index="i">
		<cfif structKeyExists(this, i) AND i IS NOT variables.primary_key>
			<cfset update_columns = listAppend(update_columns, i)>
		</cfif>
	</cfloop>

	<cfquery name="get_id_query" datasource="ss_userlevel" maxrows="1">
	SELECT #variables.primary_key#
	FROM #variables.table_name#
	WHERE #variables.primary_key# = #this[variables.primary_key]#
	</cfquery>

	<cfif get_id_query.recordcount IS NOT 0>

		<cfquery name="update_query" datasource="ss_master">
		UPDATE #variables.table_name#
		SET
		<cfloop list="#update_columns#" index="i">
			<cfset pos = pos + 1>
			#i# = <cfqueryparam cfsqltype="#variables.column_info[i].cf_sql_type#" value="#this[i]#" null="#this[i] IS ''#">
			<cfif listLen(update_columns) GT pos>
				,
			</cfif>
		</cfloop>
		WHERE #variables.primary_key# = #this[variables.primary_key]#
		</cfquery>
		<cfreturn true>
	<cfelse>
		<cfreturn false>
	</cfif>
</cffunction>


<cffunction name="expireCache" returntype="any" access="public" output="false">

	<cfset "application.wheels.caches.#variables.model_name#" = "smart_cache_id_#dateFormat(now(), 'yyyymmdd')#_#timeFormat(now(), 'HHmmss')#_#randRange(1000,9999)#">
</cffunction>


<cffunction name="findByID" returntype="any" access="public" output="false">
	<cfargument name="id" type="any" required="yes">
	<cfargument name="select" type="any" required="no" default="">
	<cfargument name="include" type="any" required="no" default="">
	<cfargument name="joins" type="any" required="no" default="">
	<cfargument name="cache" type="any" required="no" default="">

	<cfset var local = structNew()>

	<cfset local.find_all_arguments = duplicate(arguments)>
	<cfset structInsert(local.find_all_arguments, "where", "#variables.table_name#.#variables.primary_key# = #arguments.id#")>
	<cfset structDelete(local.find_all_arguments, "id")>
	<cfset local.return_object = findAll(argumentCollection=local.find_all_arguments)>

	<cfreturn local.return_object>
</cffunction>


<cffunction name="findOne" returntype="any" access="public" output="false">
	<cfargument name="select" type="any" required="no" default="">
	<cfargument name="where" type="any" required="no" default="">
	<cfargument name="order" type="any" required="no" default="">
	<cfargument name="include" type="any" required="no" default="">
	<cfargument name="joins" type="any" required="no" default="">
	<cfargument name="cache" type="any" required="no" default="">

	<cfset var local = structNew()>

	<cfset local.find_all_arguments = duplicate(arguments)>
	<cfset structInsert(local.find_all_arguments, "limit", 1)>
	<cfset local.return_object = findAll(argumentCollection=local.find_all_arguments)>

	<cfreturn local.return_object>
</cffunction>


<cffunction name="findAll" returntype="any" access="public" output="false">
	<cfargument name="select" type="any" required="no" default="">
	<cfargument name="where" type="any" required="no" default="">
	<cfargument name="order" type="any" required="no" default="">
	<cfargument name="include" type="any" required="no" default="">
	<cfargument name="page" type="any" required="no" default=0>
	<cfargument name="per_page" type="any" required="no" default=10>
	<cfargument name="joins" type="any" required="no" default="">
	<cfargument name="distinct" type="any" required="no" default="false">
	<cfargument name="limit" type="any" required="no" default=0>
	<cfargument name="cache" type="any" required="no" default="">

	<cfset var local = structNew()>

	<cfset local.select_clause = createSelectClause(argumentCollection=duplicate(arguments))>
	<cfset local.from_clause = createfromClause(argumentCollection=duplicate(arguments))>
	<cfset local.order_clause = createOrderClause(argumentCollection=duplicate(arguments))>
	<cfset local.where_clause = createWhereClause(argumentCollection=duplicate(arguments))>

	<cfif arguments.page IS NOT 0>
		<!--- return a paginator struct and override where clause --->
		<cfset local.pagination_arguments = duplicate(arguments)>
		<cfset local.pagination_arguments.from_clause = local.from_clause>
		<cfset local.pagination_arguments.where_clause = local.where_clause>
		<cfset local.pagination_arguments.order_clause = local.order_clause>
		<cfset local.pagination = pagination(argumentCollection=local.pagination_arguments)>
		<cfset local.paginator = local.pagination.paginator>
		<cfset local.where_clause = local.pagination.where_clause>
	</cfif>

	<cfset local.query_name = "finder_query">
	<cfif arguments.cache IS NOT "">
		<cfif isNumeric(arguments.cache)>
			<cfset local.cached_within = createTimeSpan(0,0,arguments.cache,0)>
		<cfelseif isBoolean(arguments.cache) AND arguments.cache>
			<cfset local.cached_within = createTimeSpan(1,0,0,0)>
			<cfset local.query_name = application.wheels.caches[variables.model_name]>
		</cfif>
	<cfelse>
		<cfset local.cached_within = createTimeSpan(0,0,0,0)>
	</cfif>

	<cfquery name="local.#local.query_name#" datasource="ss_userlevel" cachedwithin="#local.cached_within#">
	SELECT
	<cfif arguments.distinct>
		DISTINCT
	</cfif>
	<cfif application.database.type IS "sqlserver" AND arguments.limit IS NOT 0>
		TOP #arguments.limit#
	</cfif>
	#local.select_clause#
	FROM #local.from_clause#
	<cfif local.where_clause IS NOT "">
		WHERE #preserveSingleQuotes(local.where_clause)#
	</cfif>
	ORDER BY #local.order_clause#
	<cfif application.database.type IS "mysql5" AND arguments.limit IS NOT 0>
		LIMIT #arguments.limit#
	</cfif>
	</cfquery>

	<cfset local.new_object = newObject(local[local.query_name])>

	<cfif arguments.page IS NOT 0>
		<cfset local.new_object.paginator = structCopy(local.paginator)>
	</cfif>

	<cfreturn local.new_object>
</cffunction>


<cffunction name="pagination" returntype="any" access="private" output="false">
	<cfset var local = structNew()>

	<cfset local.pagination.paginator.current_page = arguments.page>

	<!--- remove everything from the FROM clause unless it's referenced in the WHERE or ORDER BY clause --->
	<cfset local.from_clause = "">
	<cfset local.pos = 0>
	<cfloop list="#replaceNoCase(arguments.from_clause, ' LEFT OUTER JOIN ', chr(7), 'all')#" index="local.i" delimiters="#chr(7)#">
		<cfset local.pos = local.pos + 1>
		<cfif local.pos IS 1 OR arguments.where_clause Contains (spanExcluding(local.i, " ") & ".") OR arguments.order_clause Contains (spanExcluding(local.i, " ") & ".")>
			<cfset local.from_clause = listAppend(local.from_clause, local.i, chr(7))>
		</cfif>
	</cfloop>
	<cfset local.from_clause = replaceNoCase(local.from_clause, chr(7), ' LEFT OUTER JOIN ', 'all')>

	<cfquery name="local.count_query" datasource="ss_userlevel">
	SELECT COUNT(
	<cfif local.from_clause Contains " ">
		DISTINCT
	</cfif>
	#variables.table_name#.#variables.primary_key#) AS total
	FROM #local.from_clause#
	<cfif arguments.where_clause IS NOT "">
		WHERE #preserveSingleQuotes(arguments.where_clause)#
	</cfif>
	</cfquery>

	<cfset local.pagination.paginator.total_records = local.count_query.total>
	<cfset local.pagination.paginator.total_pages = ceiling(local.pagination.paginator.total_records/arguments.per_page)>

	<cfset local.offset = (arguments.page * arguments.per_page) - (arguments.per_page)>
	<cfset local.limit = arguments.per_page>
	<cfif (local.limit + local.offset) GT local.pagination.paginator.total_records>
		<cfset local.limit = local.pagination.paginator.total_records - local.offset>
	</cfif>

	<cfif local.limit LTE 0>

		<cfset local.pagination.where_clause = "#variables.table_name#.#variables.primary_key# IN (0)">

	<cfelse>

		<!--- Create select clauses which contains the primary key and the order by clause (need this when using DISTINCT and for SQL Server sub queries), with and without full table name qualification --->
		<cfset local.select_clause_with_tables = variables.table_name & "." & variables.primary_key>
		<cfif variables.primary_key IS NOT "id">
			<cfset local.select_clause_with_tables = local.select_clause_with_tables & " AS id">
		</cfif>
		<cfif arguments.order_clause IS NOT "#variables.table_name#.#variables.primary_key# ASC">
			<cfset local.select_clause_with_tables = local.select_clause_with_tables &  "," & replaceList(arguments.order_clause, " ASC, DESC", ",")>
		</cfif>

		<cfset local.select_clause_without_tables = variables.primary_key>
		<cfif arguments.order_clause IS NOT "#variables.table_name#.#variables.primary_key# ASC">
			<cfset local.select_clause_without_tables = local.select_clause_without_tables &  "," & replaceList(reReplaceNoCase(arguments.order_clause, "[^,]*\.", "", "all"), " ASC, DESC", ",")>
		</cfif>

		<cfquery name="local.ids_query" datasource="ss_userlevel">
		<cfif application.database.type IS "mysql5">
			SELECT
			<cfif local.from_clause Contains " ">
				DISTINCT
			</cfif>
			#local.select_clause_with_tables#
			FROM #local.from_clause#
			<cfif arguments.where_clause IS NOT "">
				WHERE #preserveSingleQuotes(arguments.where_clause)#
			</cfif>
			ORDER BY #arguments.order_clause#
			<cfif local.limit IS NOT 0>
				LIMIT #local.limit#
			</cfif>
			<cfif local.offset IS NOT 0>
				OFFSET #local.offset#
			</cfif>
		<cfelseif application.database.type IS "sqlserver">
			SELECT #local.select_clause_without_tables#
			FROM (
				SELECT TOP #local.limit# #local.select_clause_without_tables#
				FROM (
					SELECT
					<cfif local.from_clause Contains " ">
						DISTINCT
					</cfif>
					TOP #(local.limit + local.offset)# #local.select_clause_with_tables#
					FROM #local.from_clause#
					<cfif arguments.where_clause IS NOT "">
						WHERE #preserveSingleQuotes(arguments.where_clause)#
					</cfif>
					ORDER BY #arguments.order_clause#<cfif listContainsNoCase(arguments.order_clause, "#variables.table_name#.#variables.primary_key# ") IS 0>, #variables.table_name#.#variables.primary_key# ASC</cfif>) as x
				ORDER BY #replaceNoCase(replaceNoCase(replaceNoCase(reReplaceNoCase(arguments.order_clause, "[^,]*\.", "", "all"), "DESC", chr(7), "all"), "ASC", "DESC", "all"), chr(7), "ASC", "all")#<cfif listContainsNoCase(reReplaceNoCase(arguments.order_clause, "[^,]*\.", "", "all"), "#variables.primary_key# ") IS 0>, #variables.primary_key# DESC</cfif>) as y
			ORDER BY #reReplaceNoCase(arguments.order_clause, "[^,]*\.", "", "all")#<cfif listContainsNoCase(reReplaceNoCase(arguments.order_clause, "[^,]*\.", "", "all"), "#variables.primary_key# ") IS 0>, #variables.primary_key# ASC</cfif>
		</cfif>
		</cfquery>

		<cfset local.pagination.where_clause = "#variables.table_name#.#variables.primary_key# IN (#valueList(local.ids_query.id)#)">

	</cfif>

	<cfreturn local.pagination>
</cffunction>


<cffunction name="createSelectClause" returntype="any" access="private" output="true">

	<cfset var local = structNew()>

	<cfif structKeyExists(arguments, "select") AND (arguments.select Contains " AS " OR arguments.select Contains ".")>
		<cfset local.select_clause = arguments.select>
	<cfelse>
		<cfset local.models = variables.model_name>
		<cfset local.select_clause = "">
		<!--- <cfif arguments.include IS NOT "">
			<cfset local.pos = 1>
			<cfset local.parent = variables.model_name>
			<cfset local.include = replace(arguments.include, " ", "", "all") & " ">
			<cfloop from="1" to="#listLen(replace(arguments.include,'(',',','all'))#" index="local.i">
				<cfset local.delim_pos = findOneOf("(), ", local.include, local.pos)>
				<cfset local.delim = mid(local.include, local.delim_pos, 1)>
				<cfset local.name = mid(local.include, local.pos, local.delim_pos-local.pos)>
				<cfset local.pos = REFindNoCase("[a-z]", local.include, local.delim_pos)>
				<cfset local.model = model(listLast(local.parent))>
				<cfset local.model_associations = local.model.getAssociations()>
				<cfset local.models = listAppend(local.models, local.model_associations[local.name].model_name)>
				<cfif local.delim IS "(">
					<cfset local.parent = listAppend(local.parent, local.model_associations[local.name].model_name)>
				<cfelseif local.delim IS ")">
					<cfset local.parent = listDeleteAt(local.parent, listLen(local.parent))>
				</cfif>
			</cfloop>
		</cfif> --->
		<cfloop list="#local.models#" index="local.i">
			<cfset local.columns = model(local.i).columns()>
			<cfset local.table_name = model(local.i).getTableName()>
			<cfloop list="#local.columns#" index="local.j">
				<cfif NOT structKeyExists(arguments, "select") OR arguments.select IS "" OR listFindNoCase(replace(arguments.select, " ", "", "all"), local.j)>
					<cfset local.to_add = "#local.i#_#local.j#">
					<cfset local.select_clause = listAppend(local.select_clause, "#local.table_name#.#local.j# AS #local.to_add#")>
				</cfif>
			</cfloop>
		</cfloop>
	</cfif>

	<cfreturn local.select_clause>
</cffunction>


<cffunction name="createFromClause" returntype="any" access="private" output="false">

	<cfset var local = structNew()>

	<cfset local.from_clause = variables.table_name>

	<!--- <cfif arguments.include IS NOT "">
		<cfset local.pos = 1>
		<cfset local.parent = variables.model_name>
		<cfset local.include = replace(arguments.include, " ", "", "all") & " ">
		<cfloop from="1" to="#listLen(replace(arguments.include,'(',',','all'))#" index="local.i">
			<cfset local.delim_pos = findOneOf("(), ", local.include, local.pos)>
			<cfset local.delim = mid(local.include, local.delim_pos, 1)>
			<cfset local.name = mid(local.include, local.pos, local.delim_pos-local.pos)>
			<cfset local.pos = REFindNoCase("[a-z]", local.include, local.delim_pos)>
			<cfset local.model = model(listLast(local.parent))>
			<cfset local.model_associations = local.model.getAssociations()>
			<cfif local.model_associations[local.name].type IS "has_one" OR local.model_associations[local.name].type IS "has_many">
				<cfset local.from_clause = local.from_clause & " " & "LEFT OUTER JOIN #model(local.model_associations[local.name].model_name).getTableName()# on #local.model.getTableName()#.#local.model.getPrimaryKey()# = #model(local.model_associations[local.name].model_name).getTableName()#.#local.model_associations[local.name].foreign_key#">
			<cfelseif local.model_associations[local.name].type IS "belongs_to">
				<cfset local.from_clause = local.from_clause & " " & "LEFT OUTER JOIN #model(local.model_associations[local.name].model_name).getTableName()# ON #local.model.getTableName()#.#local.model_associations[local.name].foreign_key# = #model(local.model_associations[local.name].model_name).getTableName()#.#model(local.model_associations[local.name].model_name).getPrimaryKey()#">
			<cfelseif variables.associations[local.association_name].type IS "has_and_belongs_to_many">
				<cfif left(lCase(innerModel.getTableName()), 1) LT left(lCase(outerModel.getTableName()), 1)>
					<cfset joinTable = innerModel.getTableName() & "_" & outerModel.getTableName()>
				<cfelse>
					<cfset joinTable = outerModel.getTableName() & "_" & innerModel.getTableName()>
				</cfif>
				<cfset fromTables = "LEFT OUTER JOIN #joinTable# ON #outerModel.getTableName()#.#outerModel.getPrimaryKey()# = #joinTable#.#outerModel.getModelName()#_id LEFT OUTER JOIN #innerModel.getTableName()# ON #joinTable#.#innerModel.getModelName()#_id = #innerModel.getTableName()#.#innerModel.getPrimaryKey()#" & " " & fromTables>
			</cfif>
			<cfif local.delim IS "(">
				<cfset local.parent = listAppend(local.parent, local.model_associations[local.name].model_name)>
			<cfelseif local.delim IS ")">
				<cfset local.parent = listDeleteAt(local.parent, listLen(local.parent))>
			</cfif>
		</cfloop>
	</cfif> --->

	<cfif structKeyExists(arguments, "joins") AND arguments.joins IS NOT "">
		<cfset local.from_clause = local.from_clause & " " & arguments.joins>
	</cfif>

	<cfreturn local.from_clause>
</cffunction>


<cffunction name="createWhereClause" returntype="any" access="private" output="false">

	<cfset var local = structNew()>

	<cfif structKeyExists(arguments, "where") AND arguments.where IS NOT "" AND listFindNoCase(variables.columns, "deleted_at") IS 0>
		<cfset local.where_clause = arguments.where>
	<cfelseif structKeyExists(arguments, "where") AND arguments.where IS NOT "" AND listFindNoCase(variables.columns, "deleted_at") IS NOT 0>
		<cfset local.where_clause = "#arguments.where# AND #variables.table_name#.deleted_at IS NULL">
	<cfelseif listFindNoCase(variables.columns, "deleted_at") IS NOT 0>
		<cfset local.where_clause = "#variables.table_name#.deleted_at IS NULL">
	<cfelse>
		<cfset local.where_clause = "">
	</cfif>

	<cfreturn local.where_clause>
</cffunction>


<cffunction name="createOrderClause" returntype="any" access="private" output="false">

	<cfset var local = structNew()>

	<cfset local.order_clause = "">

	<cfif structKeyExists(arguments, "order") AND arguments.order IS NOT "">
		<cfloop list="#arguments.order#" index="local.i">
			<cfif local.i Does Not Contain "ASC" AND local.i Does Not Contain "DESC">
				<cfset local.i = trim(local.i) & " ASC">
			</cfif>
			<cfif local.i Contains ".">
				<cfset local.order_clause = listAppend(local.order_clause, trim(local.i))>
			<cfelse>
				<cfset local.order_clause = listAppend(local.order_clause, "#variables.table_name#.#trim(local.i)#")>
			</cfif>
		</cfloop>
	<cfelse>
		<cfset local.order_clause = variables.table_name & "." & variables.primary_key & " ASC">
	</cfif>

	<cfreturn local.order_clause>
</cffunction>


<cffunction name="update" returntype="any" access="public" output="false">
	<cfargument name="attributes" type="any" required="no" default="#structNew()#">
	<cfset var local = structNew()>

	<cfloop collection="#arguments#" item="local.i">
		<cfif local.i IS NOT "attributes">
			<cfset arguments.attributes[local.i] = arguments[local.i]>
		</cfif>
	</cfloop>

	<cfloop collection="#arguments.attributes#" item="local.i">
		<cfset this[local.i] = arguments.attributes[local.i]>
		<cfset this.query['#variables.model_name#_#local.i#'][1] = arguments.attributes[local.i]>
	</cfloop>

	<cfreturn save()>
</cffunction>


<cffunction name="updateByID" returntype="any" access="public" output="false">
	<cfargument name="id" type="any" required="yes">
	<cfargument name="attributes" type="any" required="no" default="#structNew()#">
	<cfargument name="instantiate" type="any" required="no" default="true">
	<cfset var local = structNew()>

	<cfset local.object = findByID(arguments.id)>

	<cfloop collection="#arguments#" item="local.i">
		<cfif local.i IS NOT "id">
			<cfif isStruct(arguments[local.i])>
				<cfset local.args.attributes = arguments[local.i]>
			<cfelse>
				<cfset local.args[local.i] = arguments[local.i]>
			</cfif>
		</cfif>
	</cfloop>

	<cfset local.object.update(argumentCollection=local.args)>

	<cfreturn local.object>
</cffunction>


<cffunction name="updateOne" returntype="any" access="public" output="false">
</cffunction>


<cffunction name="updateAll" returntype="any" access="public" output="false">
	<cfargument name="where" type="any" required="no" default="">
	<cfargument name="attributes" type="any" required="no" default="#structNew()#">
	<cfargument name="instantiate" type="any" required="no" default="false">
	<cfset var local = structNew()>

	<cfquery name="local.check_updated" datasource="ss_userlevel">
		SELECT #variables.primary_key#
		FROM #variables.table_name#
		<cfif arguments.where IS NOT "">
			WHERE #preserveSingleQuotes(arguments.where)#
		</cfif>
	</cfquery>

	<cfif local.check_updated.recordcount IS NOT 0>
		<cfquery name="local.update_record" datasource="ss_master">
			UPDATE #variables.table_name#
			SET #preserveSingleQuotes(arguments.updates)#
			<cfif arguments.conditions IS NOT "">
				WHERE #preserveSingleQuotes(arguments.conditions)#
			</cfif>
		</cfquery>
	</cfif>

	<cfreturn local.check_updated.recordcount>
</cffunction>


<cffunction name="delete" returntype="any" access="public" output="false">

	<cfset var local = structNew()>

	<cfif isDefined("beforeDelete") AND NOT beforeDelete()>
		<cfreturn false>
	</cfif>

	<cfquery name="local.check_deleted" datasource="ss_userlevel">
	SELECT #variables.primary_key#
	FROM #variables.table_name#
	WHERE #variables.primary_key# = #this[variables.primary_key]#
	</cfquery>

	<cfif local.check_deleted.recordcount IS NOT 0>
		<cfif listFindNoCase(variables.columns, "deleted_at") IS NOT 0>
			<cfquery name="local.delete_record" datasource="ss_master">
			UPDATE #variables.table_name#
			SET deleted_at = #createODBCDateTime(now())#
			WHERE #variables.primary_key# = #this[variables.primary_key]#
			</cfquery>
		<cfelse>
			<cfquery name="local.delete_record" datasource="ss_master">
			DELETE
			FROM #variables.table_name#
			WHERE #variables.primary_key# = #this[variables.primary_key]#
			</cfquery>
		</cfif>
	</cfif>

	<cfif isDefined("afterDelete") AND NOT afterDelete()>
		<cfreturn false>
	</cfif>

	<cfreturn local.check_deleted.recordcount>
</cffunction>


<cffunction name="deleteByID" returntype="any" access="public" output="false">
</cffunction>


<cffunction name="deleteOne" returntype="any" access="public" output="false">
</cffunction>


<cffunction name="deleteAll" returntype="any" access="public" output="false">
</cffunction>


<cffunction name="addError" returntype="any" access="public" output="false">
	<cfargument name="field" type="any" required="yes">
	<cfargument name="message" type="any" required="yes">

	<cfset var local = structNew()>

	<cfset local.error.field = arguments.field>
	<cfset local.error.message = arguments.message>

	<cfset arrayAppend(this.errors, local.error)>

	<cfreturn true>
</cffunction>


<cffunction name="valid" returntype="any" access="public" output="false">
	<cfif isNewRecord()>
		<cfset validateOnCreate()>
	<cfelse>
		<cfset validateOnUpdate()>
	</cfif>
	<cfset validate()>
	<cfreturn errorsIsEmpty()>
</cffunction>


<cffunction name="errorsIsEmpty" returntype="any" access="public" output="false">
	<cfif arrayLen(this.errors) GT 0>
		<cfreturn false>
	<cfelse>
		<cfreturn true>
	</cfif>
</cffunction>


<cffunction name="clearErrors" returntype="any" access="public" output="false">
	<cfset arrayClear(this.errors)>
	<cfreturn true>
</cffunction>


<cffunction name="errorsFullMessages" returntype="any" access="public" output="false">

	<cfset var all_error_messages = arrayNew(1)>

	<cfloop from="1" to="#arrayLen(this.errors)#" index="i">
		<cfset arrayAppend(all_error_messages, this.errors[i].message)>
	</cfloop>

	<cfif arrayLen(all_error_messages) IS 0>
		<cfreturn false>
	<cfelse>
		<cfreturn all_error_messages>
	</cfif>
</cffunction>


<cffunction name="errorsOn" returntype="any" access="public" output="false">
	<cfargument name="field" type="any" required="yes">

	<cfset var all_error_messages = arrayNew(1)>

	<cfloop from="1" to="#arrayLen(this.errors)#" index="i">
		<cfif this.errors[i].field IS arguments.field>
			<cfset arrayAppend(all_error_messages, this.errors[i].message)>
		</cfif>
	</cfloop>

	<cfif arrayLen(all_error_messages) IS 0>
		<cfreturn false>
	<cfelse>
		<cfreturn all_error_messages>
	</cfif>
</cffunction>


<cffunction name="validatesConfirmationOf" returntype="any" access="public" output="false">
	<cfargument name="field" type="any" required="yes">
	<cfargument name="message" type="any" required="no" default="#arguments.field# is reserved">
	<cfargument name="on" type="any" required="no" default="save">

	<cfset "variables.validations_on_#arguments.on#.validates_confirmation_of.#arguments.field#.message" = arguments.message>

</cffunction>


<cffunction name="validatesExclusionOf" returntype="any" access="public" output="false">
	<cfargument name="field" type="any" required="yes">
	<cfargument name="message" type="any" required="no" default="#arguments.field# is reserved">
	<cfargument name="in" type="any" required="yes">
	<cfargument name="allow_nil" type="any" required="no" default="false">

	<cfset arguments.in = replace(arguments.in, ", ", ",", "all")>

	<cfset "variables.validations_on_save.validates_exclusion_of.#arguments.field#.message" = arguments.message>
	<cfset "variables.validations_on_save.validates_exclusion_of.#arguments.field#.allow_nil" = arguments.allow_nil>
	<cfset "variables.validations_on_save.validates_exclusion_of.#arguments.field#.in" = arguments.in>

</cffunction>


<cffunction name="validatesFormatOf" returntype="any" access="public" output="false">
	<cfargument name="field" type="any" required="yes">
	<cfargument name="message" type="any" required="no" default="#arguments.field# is invalid">
	<cfargument name="allow_nil" type="any" required="no" default="false">
	<cfargument name="with" type="any" required="yes">
	<cfargument name="on" type="any" required="no" default="save">

	<cfset "variables.validations_on_#arguments.on#.validates_format_of.#arguments.field#.message" = arguments.message>
	<cfset "variables.validations_on_#arguments.on#.validates_format_of.#arguments.field#.allow_nil" = arguments.allow_nil>
	<cfset "variables.validations_on_#arguments.on#.validates_format_of.#arguments.field#.with" = arguments.with>

</cffunction>


<cffunction name="validatesInclusionOf" returntype="any" access="public" output="false">
	<cfargument name="field" type="any" required="yes">
	<cfargument name="message" type="any" required="no" default="#arguments.field# is not included in the list">
	<cfargument name="in" type="any" required="yes">
	<cfargument name="allow_nil" type="any" required="no" default="false">

	<cfset arguments.in = replace(arguments.in, ", ", ",", "all")>

	<cfset "variables.validations_on_save.validates_inclusion_of.#arguments.field#.message" = arguments.message>
	<cfset "variables.validations_on_save.validates_inclusion_of.#arguments.field#.allow_nil" = arguments.allow_nil>
	<cfset "variables.validations_on_save.validates_inclusion_of.#arguments.field#.in" = arguments.in>

</cffunction>


<cffunction name="validatesLengthOf" returntype="any" access="public" output="false">
	<cfargument name="field" type="any" required="yes">
	<cfargument name="message" type="any" required="no" default="#arguments.field# is the wrong length">
	<cfargument name="allow_nil" type="any" required="no" default="false">
	<cfargument name="exactly" type="any" required="no" default=0>
	<cfargument name="maximum" type="any" required="no" default=0>
	<cfargument name="minimum" type="any" required="no" default=0>
	<cfargument name="within" type="any" required="no" default="">
	<cfargument name="on" type="any" required="no" default="save">

	<cfif arguments.within IS NOT "">
		<cfset arguments.within = listToArray(replace(arguments.within, ", ", ",", "all"))>
	</cfif>

	<cfset "variables.validations_on_#arguments.on#.validates_length_of.#arguments.field#.message" = arguments.message>
	<cfset "variables.validations_on_#arguments.on#.validates_length_of.#arguments.field#.allow_nil" = arguments.allow_nil>
	<cfset "variables.validations_on_#arguments.on#.validates_length_of.#arguments.field#.exactly" = arguments.exactly>
	<cfset "variables.validations_on_#arguments.on#.validates_length_of.#arguments.field#.maximum" = arguments.maximum>
	<cfset "variables.validations_on_#arguments.on#.validates_length_of.#arguments.field#.minimum" = arguments.minimum>
	<cfset "variables.validations_on_#arguments.on#.validates_length_of.#arguments.field#.within" = arguments.within>

</cffunction>


<cffunction name="validatesNumericalityOf" returntype="any" access="public" output="false">
	<cfargument name="field" type="any" required="yes">
	<cfargument name="message" type="any" required="no" default="#arguments.field# is not a number">
	<cfargument name="allow_nil" type="any" required="no" default="false">
	<cfargument name="only_integer" type="any" required="false" default="false">
	<cfargument name="on" type="any" required="no" default="save">

	<cfset "variables.validations_on_#arguments.on#.validates_numericality_of.#arguments.field#.message" = arguments.message>
	<cfset "variables.validations_on_#arguments.on#.validates_numericality_of.#arguments.field#.allow_nil" = arguments.allow_nil>
	<cfset "variables.validations_on_#arguments.on#.validates_numericality_of.#arguments.field#.only_integer" = arguments.only_integer>

</cffunction>


<cffunction name="validatesPresenceOf" returntype="any" access="public" output="false">
	<cfargument name="field" type="any" required="yes">
	<cfargument name="message" type="any" required="no" default="#arguments.field# can't be empty">
	<cfargument name="on" type="any" required="no" default="save">

	<cfset "variables.validations_on_#arguments.on#.validates_presence_of.#arguments.field#.message" = arguments.message>

</cffunction>


<cffunction name="validatesUniquenessOf" returntype="any" access="public" output="false">
	<cfargument name="field" type="any" required="yes">
	<cfargument name="message" type="any" required="no" default="#arguments.field# has already been taken">
	<cfargument name="scope" type="any" required="no" default="">

	<cfset arguments.scope = replace(arguments.scope, ", ", ",", "all")>

	<cfset "variables.validations_on_save.validates_uniqueness_of.#arguments.field#.message" = arguments.message>
	<cfset "variables.validations_on_save.validates_uniqueness_of.#arguments.field#.scope" = arguments.scope>

</cffunction>


<cffunction name="validate" returntype="any" access="public" output="false">
	<cfif structKeyExists(variables, "validations_on_save")>
		<cfset runValidation(variables.validations_on_save)>
	</cfif>
</cffunction>


<cffunction name="validateOnCreate" returntype="any" access="public" output="false">
	<cfif structKeyExists(variables, "validations_on_create")>
		<cfset runValidation(variables.validations_on_create)>
	</cfif>
</cffunction>


<cffunction name="validateOnUpdate" returntype="any" access="public" output="false">
	<cfif structKeyExists(variables, "validations_on_update")>
		<cfset runValidation(variables.validations_on_update)>
	</cfif>
</cffunction>


<cffunction name="runValidation" returntype="any" access="private" output="false">
	<cfargument name="validations" type="any" required="yes">

	<cfset var settings = "">
	<cfset var type = "">
	<cfset var field = "">
	<cfset var find_query = "">
	<cfset var i = "">
	<cfset var pos = 0>
	<cfset var virtual_confirm_field = "">

	<cfloop collection="#arguments.validations#" item="type">
		<cfloop collection="#arguments.validations[type]#" item="field">
			<cfset settings = arguments.validations[type][field]>
			<cfswitch expression="#type#">
				<cfcase value="validates_confirmation_of">
					<cfset virtual_confirm_field = "#field#_confirmation">
					<cfif structKeyExists(this, virtual_confirm_field)>
						<cfif this[field] IS NOT this[virtual_confirm_field]>
							<cfset addError(virtual_confirm_field, settings.message)>
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="validates_exclusion_of">
					<cfif NOT settings.allow_nil AND (NOT structKeyExists(this, field) OR this[field] IS "")>
						<cfset addError(field, settings.message)>
					<cfelse>
						<cfif structKeyExists(this, field) AND this[field] IS NOT "">
							<cfif listFindNoCase(settings.in, this[field]) IS NOT 0>
								<cfset addError(field, settings.message)>
							</cfif>
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="validates_format_of">
					<cfif NOT settings.allow_nil AND (NOT structKeyExists(this, field) OR this[field] IS "")>
						<cfset addError(field, settings.message)>
					<cfelse>
						<cfif structKeyExists(this, field) AND this[field] IS NOT "">
							<cfif NOT REFindNoCase(settings.with, this[field])>
								<cfset addError(field, settings.message)>
							</cfif>
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="validates_inclusion_of">
					<cfif NOT settings.allow_nil AND (NOT structKeyExists(this, field) OR this[field] IS "")>
						<cfset addError(field, settings.message)>
					<cfelse>
						<cfif structKeyExists(this, field) AND this[field] IS NOT "">
							<cfif listFindNoCase(settings.in, this[field]) IS 0>
								<cfset addError(field, settings.message)>
							</cfif>
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="validates_length_of">
					<cfif NOT settings.allow_nil AND (NOT structKeyExists(this, field) OR this[field] IS "")>
						<cfset addError(field, settings.message)>
					<cfelse>
						<cfif structKeyExists(this, field) AND this[field] IS NOT "">
							<cfif settings.maximum IS NOT 0>
								<cfif len(this[field]) GT settings.maximum>
									<cfset addError(field, settings.message)>
								</cfif>
							<cfelseif settings.minimum IS NOT 0>
								<cfif len(this[field]) LT settings.minimum>
									<cfset addError(field, settings.message)>
								</cfif>
							<cfelseif settings.exactly IS NOT 0>
								<cfif len(this[field]) IS NOT settings.exactly>
									<cfset addError(field, settings.message)>
								</cfif>
							<cfelseif isArray(settings.within) AND arrayLen(settings.within) IS NOT 0>
								<cfif len(this[field]) LT settings.within[1] OR len(this[field]) GT settings.within[2]>
									<cfset addError(field, settings.message)>
								</cfif>
							</cfif>
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="validates_numericality_of">
					<cfif NOT settings.allow_nil AND (NOT structKeyExists(this, field) OR this[field] IS "")>
						<cfset addError(field, settings.message)>
					<cfelse>
						<cfif structKeyExists(this, field) AND this[field] IS NOT "">
							<cfif NOT isNumeric(this[field])>
								<cfset addError(field, settings.message)>
							<cfelseif settings.only_integer AND round(this[field]) IS NOT this[field]>
								<cfset addError(field, settings.message)>
							</cfif>
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="validates_presence_of">
					<cfif NOT structKeyExists(this, field) OR this[field] IS "">
						<cfset addError(field, settings.message)>
					</cfif>
				</cfcase>
				<cfcase value="validates_uniqueness_of">
					<cfquery name="find_query" datasource="ss_userlevel">
						SELECT #variables.primary_key#, #field#
						FROM #variables.table_name#
						WHERE #field# = '#this[field]#'
						<cfif settings.scope IS NOT "">
							AND
							<cfset pos = 0>
							<cfloop list="#settings.scope#" index="i">
								<cfset pos = pos + 1>
								#i# = '#this[i]#'
								<cfif listLen(settings.scope) GT pos>
									AND
								</cfif>
							</cfloop>
						</cfif>
					</cfquery>
					<cfif (NOT structKeyExists(this, variables.primary_key) AND find_query.recordcount GT 0) OR (structKeyExists(this, variables.primary_key) AND find_query.recordcount GT 0 AND find_query[variables.primary_key][1] IS NOT this[variables.primary_key])>
						<cfset addError(field, settings.message)>
					</cfif>
				</cfcase>
			</cfswitch>
		</cfloop>
	</cfloop>

</cffunction>


<cffunction name="sum" returntype="any" access="public" output="false">
	<cfargument name="field" type="any" required="yes">
	<cfargument name="where" type="any" required="no" default="">
	<cfargument name="distinct" type="any" required="no" default="false">

	<cfset var sum_query = "">
	<cfset var from_clause = "">

	<cfset from_clause = createFromClause(argumentCollection=arguments)>

	<cfquery name="sum_query" datasource="ss_userlevel">
		SELECT SUM(<cfif arguments.distinct>DISTINCT </cfif>#arguments.field#) AS total
		FROM #from_clause#
		<cfif arguments.where IS NOT "" AND listFindNoCase(variables.columns, "deleted_at") IS 0>
			WHERE #preserveSingleQuotes(arguments.where)#
		<cfelseif arguments.where IS NOT "" AND listFindNoCase(variables.columns, "deleted_at") IS NOT 0>
			WHERE #preserveSingleQuotes(arguments.where)# AND #variables.table_name#.deleted_at IS NULL
		<cfelseif arguments.where IS "" AND listFindNoCase(variables.columns, "deleted_at") IS NOT 0>
			WHERE #variables.table_name#.deleted_at IS NULL
		</cfif>
	</cfquery>

	<cfreturn sum_query.total>
</cffunction>


<cffunction name="minimum" returntype="any" access="public" output="false">
	<cfargument name="field" type="any" required="yes">
	<cfargument name="where" type="any" required="no" default="">

	<cfset var minimum_query = "">
	<cfset var from_clause = "">

	<cfset from_clause = createFromClause(argumentCollection=arguments)>

	<cfquery name="minimum_query" datasource="ss_userlevel">
		SELECT MIN(#arguments.field#) AS minimum
		FROM #from_clause#
		<cfif arguments.where IS NOT "" AND listFindNoCase(variables.columns, "deleted_at") IS 0>
			WHERE #preserveSingleQuotes(arguments.where)#
		<cfelseif arguments.where IS NOT "" AND listFindNoCase(variables.columns, "deleted_at") IS NOT 0>
			WHERE #preserveSingleQuotes(arguments.where)# AND #variables.table_name#.deleted_at IS NULL
		<cfelseif arguments.where IS "" AND listFindNoCase(variables.columns, "deleted_at") IS NOT 0>
			WHERE #variables.table_name#.deleted_at IS NULL
		</cfif>
	</cfquery>

	<cfreturn minimum_query.minimum>
</cffunction>


<cffunction name="maximum" returntype="any" access="public" output="false">
	<cfargument name="field" type="any" required="yes">
	<cfargument name="where" type="any" required="no" default="">

	<cfset var maximum_query = "">
	<cfset var from_clause = "">

	<cfset from_clause = createFromClause(argumentCollection=arguments)>

	<cfquery name="maximum_query" datasource="ss_userlevel">
		SELECT MAX(#arguments.field#) AS maximum
		FROM #from_clause#
		<cfif arguments.where IS NOT "" AND listFindNoCase(variables.columns, "deleted_at") IS 0>
			WHERE #preserveSingleQuotes(arguments.where)#
		<cfelseif arguments.where IS NOT "" AND listFindNoCase(variables.columns, "deleted_at") IS NOT 0>
			WHERE #preserveSingleQuotes(arguments.where)# AND #variables.table_name#.deleted_at IS NULL
		<cfelseif arguments.where IS "" AND listFindNoCase(variables.columns, "deleted_at") IS NOT 0>
			WHERE #variables.table_name#.deleted_at IS NULL
		</cfif>
	</cfquery>

	<cfreturn maximum_query.maximum>
</cffunction>


<cffunction name="average" returntype="any" access="public" output="false">
	<cfargument name="field" type="any" required="yes">
	<cfargument name="where" type="any" required="no" default="">
	<cfargument name="distinct" type="any" required="no" default="false">

	<cfset var average_query = "">
	<cfset var from_clause = "">
	<cfset var result = 0>

	<cfset from_clause = createFromClause(argumentCollection=arguments)>

	<cfquery name="average_query" datasource="ss_userlevel">
		SELECT AVG(<cfif arguments.distinct>DISTINCT </cfif>#arguments.field#) AS average
		FROM #from_clause#
		<cfif arguments.where IS NOT "" AND listFindNoCase(variables.columns, "deleted_at") IS 0>
			WHERE #preserveSingleQuotes(arguments.where)#
		<cfelseif arguments.where IS NOT "" AND listFindNoCase(variables.columns, "deleted_at") IS NOT 0>
			WHERE #preserveSingleQuotes(arguments.where)# AND #variables.table_name#.deleted_at IS NULL
		<cfelseif arguments.where IS "" AND listFindNoCase(variables.columns, "deleted_at") IS NOT 0>
			WHERE #variables.table_name#.deleted_at IS NULL
		</cfif>
	</cfquery>

	<cfif average_query.average IS NOT "">
		<cfset result = average_query.average>
	</cfif>

	<cfreturn result>
</cffunction>


<cffunction name="count" returntype="any" access="public" output="false">
	<cfargument name="where" type="any" required="no" default="">
	<cfargument name="joins" type="any" required="no" default="">
	<cfargument name="select" type="any" required="no" default="">
	<cfargument name="distinct" type="any" required="no" default="false">

	<cfset var local = structNew()>

	<cfif arguments.select IS "">
		<cfset arguments.select = "#variables.table_name#.#variables.primary_key#">
	</cfif>

	<cfset local.from_clause = createFromClause(argumentCollection=arguments)>

	<cfquery name="local.count_query" datasource="ss_userlevel">
		SELECT COUNT(<cfif arguments.distinct>DISTINCT </cfif>#arguments.select#) AS total
		FROM #local.from_clause#
		<cfif arguments.where IS NOT "" AND listFindNoCase(variables.columns, "deleted_at") IS 0>
			WHERE #preserveSingleQuotes(arguments.where)#
		<cfelseif arguments.where IS NOT "" AND listFindNoCase(variables.columns, "deleted_at") IS NOT 0>
			WHERE #preserveSingleQuotes(arguments.where)# AND #variables.table_name#.deleted_at IS NULL
		<cfelseif arguments.where IS "" AND listFindNoCase(variables.columns, "deleted_at") IS NOT 0>
			WHERE #variables.table_name#.deleted_at IS NULL
		</cfif>
	</cfquery>

	<cfreturn local.count_query.total>
</cffunction>