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

You'll also need to provide a configuration file for the widgets. In the configuration you should define an api key for the FMI weather widget.  Get one at [the Finnish Meteorological Institute's open data website](https://ilmatieteenlaitos.fi/rekisteroityminen-avoimen-datan-kayttajaksi). Additionally, you should also define the HSL bike stations and bus stops you wish to see. The app looks for the key in a pidash.yml file at the repository root. The file contents should look like this:

```
fmi: enter-your-api-key-here
hsl:
  bike_station_ids: ['092', '127']
  stop_ids: ['HSL:1113131']
```

You can configure the dashboard layout by editing dashboards/sample.erb to your liking.

Now you should be able to start the application by running:

```
dashing start
```

Navigate your browser to http://localhost:3030/sample.

