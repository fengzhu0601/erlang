{application,esqlite,
             [{description,"sqlite nif interface"},
              {vsn,"1"},
              {modules,[eslqite_sup,esqlite3,esqlite3_nif,esqlite_app,
                        esqlite_config]},
              {registered,[]},
              {applications,[kernel,stdlib]},
              {mod,{esqlite_app,[]}},
              {env,[]}]}.
