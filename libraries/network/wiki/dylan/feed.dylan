Module: wiki-internal

// Responder for /recent-changes/feed
define method do-feed ()
  let changes = sort(wiki-changes(),
                     test: method (change1, change2)
                             change1.date-published > change2.date-published
                           end);
  let feed-updated = ~empty?(changes) & first(changes).date-published;
  let feed-authors = #[];
  for (change in changes)
    for (author in change.authors)
      feed-authors := add-new!(feed-authors, author);
    end for;
  end for;
  let feed = make(<feed>,
                  generator: make(<generator>,
                                  text: "wiki", version: "0.1", uri: ""),
                  title: "TITLE",
                  subtitle: "SUBTITLE",
                  updated: feed-updated | current-date(),
                  author: feed-authors,
                  categories: #[]);
  let url = build-uri(current-request().request-url);
  feed.identifier := url;
  feed.links["self"] := make(<link>, rel: "self", href: url);

  add-header(current-response(), "Content-Type", "application/atom+xml");
  output("%s", generate-atom(feed, entries: changes));
end method do-feed;

define method generate-atom (change :: <wiki-change>, #key)
  let author = find-user(first(change.authors));
  with-xml()
    entry { 
      title(change.title),
//      do(do(method(x) collect(generate-atom(x)) end, entry.links)),
      id(build-uri(change-identifier(change))),
      published(generate-atom(change.date-published)),
      updated(generate-atom(change.date-published)),
      do(if (author) generate-atom(author) end if),
//      do(do(method(x) collect(generate-atom(x)) end, entry.contributors)),
      do(collect(generate-atom(change.comments[0].content)))
    } //missing: category, summary
  end;
end;

define method generate-atom (user :: <wiki-user>, #key)
  with-xml()
    author {
      name(user.user-name),
      uri(build-uri(permanent-link(user)))
    }
  end;
end;


define method change-identifier (change :: <wiki-page-change>)
  let location = page-permanent-link(change.title);
  push-last(location.uri-path, "versions");
  push-last(location.uri-path, integer-to-string(change.change-version));
  location;
end;

define method change-identifier (change :: <wiki-group-change>)
  group-permanent-link(change.title)
end;

define method change-identifier (change :: <wiki-user-change>)
  user-permanent-link(change.title)
end;

