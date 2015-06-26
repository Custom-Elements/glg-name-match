# glg-name-match
This element provides access to GLG's cerca autocomplete service. Use the `options` published attribute
to configure the cerca query options and either the `query` or `jump` methods to fire a query to the service.
When results are ready the element then fires a `results` event.

    Polymer 'glg-name-match',

## Attributes
### url
Required. The url to the cerca server, not including protocal. For example:
services.glgresearch.com/cerca

### indices
Required. A comma-delimited string listing the indices to query. There must be at least one index specified.

### matchField
Optional.  THe index field to match against.  If not specified, defaults to 'name'

### minScore
Optional.  A float between 0 and 1.  Only documents with a normalized score equal to or greater than min_score will be returned. Defaults to 0.5

### size
Optional.  An integer specifying how many results glg-name-match should return.  Defaults to 10

### fields
Optional. A comma-delimited string of cerca index field names to be returned with each document.  Defaults to all.

### secondarySortField
Optional.  By default, glg-name-match returns results sorted first by score (descending) and then by name (ascending).  If a secondarySortField is specified, it will bump name down to tertiary sort.

### secondarySortOrder
Optional. Either 'asc' or 'desc'.  By default, the secondary sort is in ascending order.  NOTE - secondarySortOrder only applies to secondarySortField.
If no secondarySortField is specified, secondarySortOrder will have no effect.

## Change-event Handlers
None

## Methods
### search
Retrieves results for either query or jump

      search: (val, type='query') ->
        opts = {}
        opts.matchField = @matchField ? 'name'
        opts.val = val
        opts.size = @size ? 10
        opts.minScore = @minScore ? 0.5
        if @fields?
          opts.fields = (field.trim() for field in @fields.split(','))
        opts.sort = [
            "_score"
        ]
        # If we have a secondarySortField, we want to include before the name sort
        if @secondarySortField?
          opts.sort.push {
             "#{@secondarySortField}": {
               order: @secondarySortOrder ? "asc"
             }
          }
        # Our last sort is always name
        opts.sort.push {
           "#{opts.matchField}.sort": {
              order: "asc"
           }
        }
        bodyFunction = if type is 'jump' then @getJumpBody else @getQueryBody
        @fetchResults bodyFunction(opts)

# fetchResults
Takes the body of the POST and makes an xhr request to the server for results

      fetchResults: (body) ->
        #TODO:  strip out protocal from url if it's there and replace it with https
        #       also need to remove any trailing slashes
        req = new XMLHttpRequest()
        req.open 'POST', "https://#{@url}/#{@indices}/_search?ignore_unavailable=true"
        req.withCredentials = true
        req.onreadystatechange = () =>
          if req.readyState is 4
            if req.status is 200
              hits = JSON.parse
              try
                hits = JSON.parse(req.responseText).hits
              catch
                error = "glg-name-match received a #{req.status} response code: #{req}"
                console.error error
                @fire 'name-match-error', error
              finally
                @fire 'name-match-results', hits
            else
              error = "glg-name-match received a #{req.status} response code: #{req}"
              console.error error
              @fire 'name-match-error', error
        req.onerror = (e) =>
          error = "glg-name-match xhr error: #{e.error}"
          console.error error
          @fire 'name-match-error', error
        req.send JSON.stringify body

### getJumpBody
Returns the body of the post for cerca jump

      getJumpBody: (opts) ->
        body =
          query: {
              match: {
                  "_id": opts.val
              }
          }
        if opts.fields?
          body.fields = opts.fields

        body

### getQueryBody
Returns the body of the post for cerca query

      getQueryBody: (opts) ->
        body =
          min_score: opts.minScore,
          query: {
            function_score: {
               filter: {
                  query: {
                     match: {
                        "#{opts.matchField}.trigram": opts.val
                     }
                  }
               },
               functions: [
                  {
                     script_score: {
                        script: "tf_script_score",
                        params: {
                           field: "#{opts.matchField}.trigram",
                           querystring: opts.val,
                           lowercase: true,
                           foldascii: true
                        },
                        lang: "native"
                     }
                  },
                  {
                     filter: {
                        query: {
                           match: {
                              "#{opts.matchField}.edgetrigram": opts.val
                           }
                        }
                     },
                     boost_factor: 0.001
                  },
                  {
                     filter: {
                        query: {
                           match: {
                              "#{opts.matchField}.sort": opts.val
                           }
                        }
                     },
                     boost_factor: 0.001
                  }
               ],
               score_mode: "sum",
               boost_mode: "replace"
            }
          },
          sort: opts.sort
          size: opts.size

        if opts.fields?
          body.fields = opts.fields

        body

### query
Retrieves results from cerca based on query text and fires the 'results' event
when results are available.

      query: (val) ->
        @search val, 'query'

### jump
Retrieves results from cerca based on object ID and fires the 'results' event
when results are available.

      # TODO:  Actually need to implement jump in our search method
      jump: (val) ->
        @search val, 'jump'
