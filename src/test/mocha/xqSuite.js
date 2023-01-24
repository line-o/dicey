'use strict'

const fs = require('fs')
const expect = require('chai').expect
const s = require('superagent')
const { readOptionsFromEnv } = require('@existdb/gulp-exist')

const testRunnerLocalPath = 'src/test/mocha/runner.xq'

const { name, version } = require('../../../package.json')
const testCollection = '/test-' + name + '-' + version
const testRunner = testCollection + '/runner.xq'

const connectionOptions = readOptionsFromEnv()

function connection (options) {
  const protocol = options.protocol ? options.protocol : 'http:'
  const port = options.port ? ':' + options.port : ''
  const path = '/exist/apps'
  const prefix = `${protocol}//${options.host}${port}${path}`
  return (request) => {
    request.url = prefix + request.url
    request.auth(options.basic_auth.user, options.basic_auth.pass)
    return request
  }
}

describe('xqSuite', function () {
  let client, result

  before(done => {
    client = s.agent().use(connection(connectionOptions))
    const buffer = fs.readFileSync(testRunnerLocalPath)
    client
        .put(testRunner)
        .set('content-type', 'application/xquery')
        .set('content-length', buffer.length)
        .send(buffer)
        .then(_ => {
          return client.get(testRunner)
            .query({lib: name, version})
            .send()
        })
        .then(response => {
          if (response.body.error) {
            console.error(response.body.error)
            return Promise.reject(
              Error(response.body.error.description))
          }
          result = response.body.result
          done()
        })
        .catch(done)
  })

  it('should return 0 errors', done => {
    expect(result.errors).to.equal(0)    
    done()
  })

  it('should return 0 failures', done => {
    expect(result.failures).to.equal(0)
    done()
  })

  it('should return 0 pending tests', done => {
    expect(result.pending).to.equal(0)
    done()
  })

  it('should have run some tests', done => {
    expect(result.tests).to.be.greaterThan(0)
    done()
  })

  it('should have finished in less than a second', done => {
    expect(result.time).to.be.lessThan(1)
    done()
  })

  // after(done => {
  //   client.delete(testCollection)
  //     .send()
  //     .then(_ => done(), done)
  // })

})
