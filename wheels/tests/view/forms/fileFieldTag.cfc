<cfcomponent extends="wheelsMapping.test">

	<cfset global.controller = createobject("component", "wheelsMapping.Controller")>

	<cffunction name="test_x_fileFieldTag_valid">
		<cfset loc.controller.fileFieldTag(name="photo")>
	</cffunction>

</cfcomponent>