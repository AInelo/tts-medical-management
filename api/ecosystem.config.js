module.exports = {
    apps: [
      {
        name: "collect-audio-api",
        script: "./dist/server.js",
        cwd: "/home/turibio/collect_audio_setup/Collecte-audio-Pionners/api",
        instances: 1,
        exec_mode: "fork",
        watch: false,
        env: {
          NODE_ENV: "production",
          PORT: 5100
        }
      }
    ]
  };
  