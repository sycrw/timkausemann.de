---
title: "MusicAnalyzer"
description: "A spotify tool"
date: 2024-08-31
type: "projects"
showHero: true
---

Music Analyzer is a tool to extract listening data from your spotify account. It was created, so you did not have to wait till the end of the year for spotify wrapped to get all your listing data.

## The Beginnings

The project got launched within the Code Club Scholarship.
Together with two fellow scholars we set out to create this project.

## Tech Stack

We chose Next.js as a full stack framework,
since at this time none of use had experience with React, hoping to learn it along the way.
Next.js also gave us a backend, so we didn't have to worry about that.
We also set up prisma with a mariadb.
For our database, our only requirement was for it to be a relational database,
and as I had a docker-compose file lying around for mariadb, we just used it.
To connect OAuth2 from Spotify, we used NextAuth(now Auth.js) which saved us a lot of headaches.

## Features

But what is Music Analyzer actually cable of?

### Top Songs and Artists

Music Analyzer shows users their top songs and artists.
Users can filter for the last 4 weeks, 6 months and 1 year.
We would like to make other time ranges available, but sadly spotify does not offer any other.

![image](images/musicanalyzer-top-artists.png "Top Artists Page")

### Playlist Generation

On the top songs page, the user can also create a playlist from his top fifty songs in his spotify account.
In my personal experience these playlists are great for whenever you feel like you don't enjoy any music at all.

### Archives

Music Analyzer also allows users to archive their top songs.
If they find their top 50 songs nice, or just want to save them for later, they can now do that.
This way you can look back on your top songs, and also generate playlists.

## What's next?

Although the scholarship has long ended, we still have some more ideas.

- Auto Archive
- Share
- Friends

[Check It Out](https://musicanalyzer.cc)
