module.exports = (grunt)->
    pkg = grunt.file.readJSON 'package.json'

    grunt.initConfig
        shell:
            mocha:
                command:'mocha --compilers coffee:coffee-script/register -b'
        coffee:
            dev:
                src:['coffee/*.coffee']
                dest:'lib/'
                ext:'.js'
                expand:true
                flatten:true

    grunt.loadNpmTasks 'grunt-shell'
    grunt.loadNpmTasks 'grunt-contrib-coffee'

    grunt.registerTask 'test','mocha tests.',(arg1,arg2)->
        fileName = arg1
        fileName += '.coffee' if not /\.coffee$/.test fileName
        fileName = 'test/'+fileName if not /^test\//.test fileName
        grunt.config ['shell','mocha','command'],'mocha --compilers coffee:coffee-script/register -w ' + fileName + ' -b' if arg1
        grunt.task.run 'shell:mocha'
