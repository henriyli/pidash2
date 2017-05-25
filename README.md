# pidash2

A simple information dashboard for my raspberry pi 3 with a 7" screen. Displays weather forecasts and public transportation information, such as bus stop departures and city bike station status. Made using dashing.io.

### usage

To host this on a raspbian, you will probably need to install ruby-dev.

```
sudo apt-get install ruby-dev
```

After cloning this repository, you'll need to install required dependencies with Bundler. 

```
bundle
```

You'll also need to provide an api key for the FMI weather widget. Get one at [the Finnish Meteorological Institute's open data website](https://ilmatieteenlaitos.fi/rekisteroityminen-avoimen-datan-kayttajaksi). The app looks for the key in a pidash.yaml file at the repository root. The file contents should look like this:

```
fmi: enter-your-api-key-here
```

Now you should be able to start the application by running:

```
dashing start
```

Navigate your browser to http://localhost:3030/sample.

