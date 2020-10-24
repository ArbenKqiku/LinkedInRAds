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

# 6 Get the information of your personal LinkedIn account ----
headers = c(
    `Authorization` = str_c("Bearer ", access_token)
)

personal_li_info = GET(url = 'https://api.linkedin.com/v2/me', add_headers(.headers=headers)) %>% 
    content()

# 7 Prepare variables to make post request to share a post ----
# URL of the request
post_URL = "https://api.linkedin.com/v2/ugcPosts"

# arguments to pass to the body
# here you'll find the full documentation: https://docs.microsoft.com/en-gb/linkedin/consumer/integrations/self-serve/share-on-linkedin
personal_urn = str_c("urn:li:person:", personal_li_info$id)
lifecycleState = "PUBLISHED"
text = "🤩 Hey, this post was created by using R and the LinkedIn User Generated Content (UGC) API"
media_category = "NONE"
visibility = "PUBLIC"

# build body
post_request_body = list(
    author = str_c("urn:li:person:", personal_li_info$id),
    lifecycleState = lifecycleState,
    specificContent = list(
        com.linkedin.ugc.ShareContent =
                    list(shareCommentary =
                             list(text = text),
                         shareMediaCategory = media_category
                    )
    ),
    visibility = list(
        com.linkedin.ugc.MemberNetworkVisibility = visibility
    )
) %>% 
    toJSON(auto_unbox = TRUE, pretty = TRUE)

# 8 Make post request to share a post ----
POST(url = post_URL, body = post_request_body, httr::add_headers(.headers = headers))

