<cfcomponent extends="wheelsMapping.test">

	<cfinclude template="/wheelsMapping/global/functions.cfm">

	<cffunction name="test_getting_children">
		<cfset loc.author = model("author").findOne(order="id")>
		<cfset loc.dynamicResult = loc.author.posts()>
		<cfset loc.coreResult = model("post").findAll(where="authorId=#loc.author.id#")>
		<cfset assert("loc.dynamicResult['title'][1] IS loc.coreResult['title'][1]")>
	</cffunction>

	<cffunction name="test_counting_children">
		<cfset loc.author = model("author").findOne(order="id")>
		<cfset loc.dynamicResult = loc.author.postCount()>
		<cfset loc.coreResult = model("post").count(where="authorId=#loc.author.id#")>
		<cfset assert("loc.dynamicResult IS loc.coreResult")>
	</cffunction>

	<cffunction name="test_checking_if_children_exist">
		<cfset loc.author = model("author").findOne(order="id")>
		<cfset loc.dynamicResult = loc.author.hasPosts()>
		<cfset loc.coreResult = model("post").exists(where="authorId=#loc.author.id#")>
		<cfset assert("loc.dynamicResult IS loc.coreResult")>
	</cffunction>

	<cffunction name="test_getting_one_child">
		<cfset loc.author = model("author").findOne(order="id")>
		<cfset loc.dynamicResult = loc.author.findOnePost()>
		<cfset loc.coreResult = model("post").findOne(where="authorId=#loc.author.id#")>
		<cfset assert("loc.dynamicResult.title IS loc.coreResult.title")>
	</cffunction>

	<cffunction name="test_adding_child_by_setting_foreign_key">
		<cfset loc.author = model("author").findOne(order="id")>
		<cfset loc.post = model("post").findOne(order="id DESC")>
		<cftransaction>
			<cfset loc.author.addPost(loc.post)>
			<!--- we need to test if authorId is set on the loc.post object as well and not just in the database! --->
			<cfset loc.post.reload()>
			<cftransaction action="rollback" />
		</cftransaction>		
		<cfset assert("loc.author.id IS loc.post.authorId")>
		<cfset loc.post.reload()>
		<cftransaction>
			<cfset loc.author.addPost(loc.post.id)>
			<cfset loc.post.reload()>
			<cftransaction action="rollback" />
		</cftransaction>		
		<cfset assert("loc.author.id IS loc.post.authorId")>
		<cfset loc.post.reload()>
		<cftransaction>
			<cfset model("post").updateByKey(key=loc.post.id, authorId=loc.author.id)>
			<cfset loc.post.reload()>
			<cftransaction action="rollback" />
		</cftransaction>		
		<cfset assert("loc.author.id IS loc.post.authorId")>
	</cffunction>

	<cffunction name="test_removing_child_by_nullifying_foreign_key">
		<cfset loc.author = model("author").findOne(order="id")>
		<cfset loc.post = model("post").findOne(order="id DESC")>
		<cftransaction>
			<cfset loc.author.removePost(loc.post)>
			<!--- we need to test if authorId is set to blank on the loc.post object as well and not just in the database! --->
			<cfset loc.post.reload()>
			<cftransaction action="rollback" />
		</cftransaction>		
		<cfset assert("loc.post.authorId IS ''")>
		<cfset loc.post.reload()>
		<cftransaction>
			<cfset loc.author.removePost(loc.post.id)>
			<cfset loc.post.reload()>
			<cftransaction action="rollback" />
		</cftransaction>
		<cfset assert("loc.post.authorId IS ''")>
		<cfset loc.post.reload()>
		<cftransaction>
			<cfset model("post").updateByKey(key=loc.post.id, authorId="")>
			<cfset loc.post.reload()>
			<cftransaction action="rollback" />
		</cftransaction>		
		<cfset assert("loc.post.authorId IS ''")>
	</cffunction>

	<cffunction name="test_deleting_child">
		<cfset loc.author = model("author").findOne(order="id")>
		<cfset loc.post = model("post").findOne(order="id DESC")>
		<cftransaction>
			<cfset loc.author.deletePost(loc.post)>
			<!--- should we also set loc.post to false here? --->
			<cfset assert("NOT model('post').exists(loc.post.id)")>
			<cftransaction action="rollback" />
		</cftransaction>
		<cftransaction>
			<cfset loc.author.deletePost(loc.post.id)>
			<cfset assert("NOT model('post').exists(loc.post.id)")>
			<cftransaction action="rollback" />
		</cftransaction>		
		<cftransaction>
			<cfset model("post").deleteByKey(loc.post.id)>
			<cfset assert("NOT model('post').exists(loc.post.id)")>
			<cftransaction action="rollback" />
		</cftransaction>		
	</cffunction>

	<cffunction name="test_removing_all_children_by_nullifying_foreign_keys">
		<cfset loc.author = model("author").findOne(order="id")>
		<cftransaction>
			<cfset loc.author.removeAllPosts()>
			<cfset loc.dynamicResult = loc.author.postCount(reload=true)>
			<cfset loc.remainingCount = model("post").count(reload=true)>
			<cftransaction action="rollback" />
		</cftransaction>
		<cftransaction>
			<cfset model("post").updateAll(authorId="", where="authorId=#loc.author.id#")>
			<cfset loc.coreResult = loc.author.postCount(reload=true)>
			<cftransaction action="rollback" />
		</cftransaction>		
		<cfset assert("loc.dynamicResult IS 0 AND loc.coreResult IS 0 AND loc.remainingCount IS 4")>
	</cffunction>

	<cffunction name="test_deleting_all_children">
		<cfset loc.author = model("author").findOne(order="id")>
		<cftransaction>
			<cfset loc.author.deleteAllPosts()>
			<cfset loc.dynamicResult = loc.author.postCount(reload=true)>
			<cfset loc.remainingCount = model("post").count(reload=true)>
			<cftransaction action="rollback" />
		</cftransaction>
		<cftransaction>
			<cfset model("post").deleteAll(where="authorId=#loc.author.id#")>
			<cfset loc.coreResult = loc.author.postCount(reload=true)>
			<cftransaction action="rollback" />
		</cftransaction>		
		<cfset assert("loc.dynamicResult IS 0 AND loc.coreResult IS 0 AND loc.remainingCount IS 1")>
	</cffunction>

	<cffunction name="test_creating_new_child">
		<cfset loc.author = model("author").findOne(order="id")>
		<cfset loc.newPost = loc.author.newPost(title="New Title")>
		<cfset loc.dynamicResult = loc.newPost.authorId>
		<cfset loc.newPost = model("post").new(authorId=loc.author.id, title="New Title")>
		<cfset loc.coreResult = loc.newPost.authorId>
		<cfset assert("loc.dynamicResult IS loc.coreResult")>
	</cffunction>

	<cffunction name="test_creating_new_child_and_saving_it">
		<cfset loc.author = model("author").findOne(order="id")>
		<cftransaction>
			<cfset loc.newPost = loc.author.createPost(title="New Title", body="New Body")>
			<cfset loc.dynamicResult = loc.newPost.authorId>
			<cftransaction action="rollback" />
		</cftransaction>
		<cftransaction>
			<cfset loc.newPost = model("post").create(authorId=loc.author.id, title="New Title", body="New Body")>
			<cfset loc.coreResult = loc.newPost.authorId>
			<cftransaction action="rollback" />
		</cftransaction>
		<cfset assert("loc.dynamicResult IS loc.coreResult")>
	</cffunction>

</cfcomponent>