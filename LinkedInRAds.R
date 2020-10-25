# Description: this piece of code will allow you to share information on your LinkedIn profile
# Author: Arben Kqiku
# Email: arben.kqiku@gmail.com

# 1 Load packages -----
library(httr)
library(tidyverse)
library(jsonlite)

# 2 -------
# Before starting, please follow the tutorial found in this video: https://www.youtube.com/watch?v=jYflkIo1R4A
# This will allow you to retrieve the client_id, client_secret, etc.
# This script is based on code on this worksheet: https://api-university.com/wp-content/uploads/2020/05/worksheet-linkedin.txt?utm_source=sendfox&utm_medium=email&utm_campaign=linkedin-api-oauth-worksheet
# My script, up to the point where I get the access token, is simply an R adaptation of this worksheet
# Credit goes to https://api-university.com for their amazing work!

# 3 Define registration variables ------
redirect_URL = "URL of your company"
redirect_URI = "Retrieve the URI of your company"
client_id = ""
client_secret = ""
scope = "w_member_social%20r_liteprofile"

# 4 Retrieve response code -----
# print the following variable in the browser to get the response code:
browser_variable = str_c("https://www.linkedin.com/oauth/v2/authorization?response_type=code&state=987654321&scope=", scope, "&client_id=", client_id, "&redirect_uri=", redirect_URI)

# once you paste the browser_variable in the browser, and you go through the LinkedIn access workflow, 
# paste the resulting URL in the variable below named browser_response
browser_response = ""
response_code = str_extract(browser_response, "(?<=code=).*(?=&state)") # extract only the response code

# 5 Retrieve access token ----
# define grant_type code variable
authorization_code = "authorization_code"

# build request URL
post_request_access_token_url = str_c('https://www.linkedin.com/oauth/v2/accessToken?grant_type=', 
                                      authorization_code, "&code=", response_code, "&redirect_uri=", 
                                      redirect_URI, "&client_id=", client_id, "&client_secret=", client_secret)

# make post request
result = httr::POST(post_request_access_token_url) %>% 
    content()

# please write access token manually otherwise you'll lose it next time you'll reconnect
access_token = "insert_your_access_token_manually"

headers = c(
    `Authorization` = str_c("Bearer ", access_token)
)

# 6 Get the information of your personal LinkedIn account ----
personal_li_info = GET(url = 'https://api.linkedin.com/v2/me', add_headers(.headers=headers)) %>% 
    content()

# 7 Prepare a share of an image -----
# Here you are basically getting a place where you can then store your image that you can use
# for subsequent posts
image_share_body = list(registerUploadRequest = 
                            list(recipes = list("urn:li:digitalmediaRecipe:feedshare-image"),
                                 owner = str_c("urn:li:person:", personal_li_info$id),
                                 serviceRelationships = list(list(
                                     relationshipType = "OWNER",
                                     identifier = "urn:li:userGeneratedContent"
                                 )))) %>% 
    
    toJSON(auto_unbox = TRUE, pretty = TRUE)

post_URL = "https://api.linkedin.com/v2/assets?action=registerUpload"

image_response = POST(url = post_URL, body = image_share_body, add_headers(.headers = headers)) %>% 
    content()

# retrieve useful variables for later
# the upload URL is the URL that we are going to use in the next request
upload_URL = image_response$value$uploadMechanism$com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest$uploadUrl
asset = image_response$value$asset

# 8 Post an image on LinkedIn that we can use later to add into a post ----
# create image upload
image_to_upload = upload_file("nasa.jpeg")

# post the image to use later 
image_post_request = POST(url = upload_URL, body = image_to_upload, add_headers(.headers = headers))

# 9 Prepare variables to make post request to share a post ----
# URL of the request
post_URL = "https://api.linkedin.com/v2/ugcPosts"

# arguments to pass to the body
# here you'll find the full documentation: https://docs.microsoft.com/en-gb/linkedin/consumer/integrations/self-serve/share-on-linkedin
personal_urn = str_c("urn:li:person:", personal_li_info$id)
lifecycleState = "PUBLISHED"
text = str_glue("✅ Hey, this post was created by using R and the LinkedIn API. This time, I also added an image.
                
                If you want to see how I did it, here is the source code: https://github.com/ArbenKqiku/LinkedInRAds/blob/main/LinkedInRAds.R",
                
                "\n\n✅ Follow me for more tips on #datascience, #digitalmarketing & #programming.
                
                #r #rstats #dailycoding #arbentips #api #linkedin #apidevelopment")
media_category = "IMAGE"
visibility = "PUBLIC"
status = "READY"
description_text = "this is an image description"
title_text = "this is an image title text"

# build body
post_request_body = list(
    author = str_c("urn:li:person:", personal_li_info$id),
    lifecycleState = lifecycleState,
    specificContent = list(
        com.linkedin.ugc.ShareContent =
            list(shareCommentary =
                     list(text = text),
                 shareMediaCategory = media_category,
                 media = list(
                     list(status = status,
                          description = list(
                              text = description_text),
                          media = asset,
                          title = list(text = title_text))
                 )
            )
    ),
    visibility = list(
        com.linkedin.ugc.MemberNetworkVisibility = visibility
    )
) %>% 
    toJSON(auto_unbox = TRUE, pretty = TRUE)

# 10 Make post request to share a post ----
POST(url = post_URL, body = post_request_body, httr::add_headers(.headers = headers)) %>% 
    content()