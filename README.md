#MTA Service Alerts

This project seeks to collect service-alert data from the MTA, record it, and expose the collected historical data through a new JSON API. 

The [official MTA service-alert API](http://web.mta.info/status/serviceStatus.txt) consists of an XML file that gives the status ("DELAYS", "PLANNED WORK", "GOOD SERVICE", or "SERVICE CHANGE") of each line at this moment. Every minute this document is updated to reflect changes in status. Additional information about the status can be found as a block of malformed HTML (intended for the MTA website) inside the text field.

Many service-alerts only affect a subset of a train line, a fact only found in the human-readable text section of the status alert. Fortunately, the language used in these descriptions is of a fairly predictable nature. If you are familiar with any natural language processing, take a look at some of the sample html below and let us know.

With this API in place, we plan to implement a friendly user interface for New Yorkers to find out about the status of train-lines-of-interest. Renderings of this web-app can be found on [our github page](https://github.com/BetaNYC/service-alerts/tree/master/design). 


##Sample HTML

These are examples of the human-readable html for different train and buses. Elements of the HTML receive inconsistent styling (e.g., station names are sometimes wrapped in `<b>` tags). These have been stripped out with regex because they often keep the HTML from validating. As an example, closing `</div>` tags are usually wrapped thusly: `<b></div></b>`.

Nevertheless, when doing natural language processing to this text, those tags may prove useful. To see examples with these (sometimes invalid) tags, check out [the research directory](https://github.com/BetaNYC/service-alerts/tree/master/research).

    <span class="TitleDelay">Delays</span>
    <span class="DateStyle">Posted: 03/04/2015  2:09PM</span>
    <P>Due to signal problems at Kings Hwy,Â southbound [F] trains are running with delays.</P>
    <P>Allow additional travel time.</P>

    <span class="TitleDelay">Delays</span>
    <span class="DateStyle">Posted: 03/04/2015  2:08PM</span>
    <P>Due to FDNY activity at Livonia Av,Â [L] trains are running with delaysin both directions.Â</P>
    <P>Allow additional travel time.</P>

    <a class="plannedWorkDetailLink" onclick="ShowHide(91145)">[L] Trains run approximately every 24 minutes between Broadway Junction and Rockaway Pkwy</a>
    <div id="91145" class="plannedWorkDetail">
      Days, 11 AM to 3:05 PM, Wed to Fri, Mar 4 - 6  •  Mon to Fri, Mar 9 - 13
      [L] service operates in two sections:
      
      1. Between 8 Av and Broadway Junction
      2. Between Broadway Junction and Rockaway Pkwy

      • Transfer at Broadway Junction to continue your trip.
    </div>


##Frontend

When the API is finalized, we would like to create a frontend for seeing the current delays laid over a subway map.


##TODO

* Figure out a unique identifier for each delay. 
  * Investigate why the MTA occassionally inclues an ID.
  * Keep track of each event between minutes.
  * Record duration for each event
* Record data in full, this way, in the event that the MTA changes the format, we can retroactively scrape the data.
* Use natural language processing to extract details about delays.
* Migrate from [our trello](https://trello.com/b/8OZwFJsL/design) to using github issues.

