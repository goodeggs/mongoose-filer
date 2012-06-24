befores = []
beforeAll = (before) ->
  befores.push before

afters = []
afterAll = (after) ->
  afters.push after

# Use Jasime reporter to implement once-per entire suite setup and teardown
jasmine.getEnv().addReporter {
  reportRunnerStarting: (runner) ->
    befores.forEach (before) -> before()
  reportRunnerResults: (runner) ->
    afters.forEach (after) -> after()
}

global.beforeAll = beforeAll
global.afterAll = afterAll

