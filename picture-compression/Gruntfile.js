const jpegtran = require('imagemin-jpegtran');
const pngquant = require('imagemin-pngquant');
module.exports = function (grunt) {
	grunt.initConfig({
		imagemin: {
			static: {
				options: {
					optimizationLevel: 3,
					svgoPlugins: [{removeViewBox: false}],
					use: [jpegtran(), pngquant()] // Example plugin usage
				},
				files: [{
					expand: true,
					cwd: 'res/',
					src: ['**/*.{png,jpg,gif}'],
					dest: 'res/'
				}]
			}
		}
	});
	grunt.loadNpmTasks('grunt-contrib-imagemin');
	grunt.registerTask('default', ['imagemin']);
}