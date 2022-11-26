package com.yocharge.YoCharge;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Intent;
import android.content.Context;

public class BootReceiver extends BroadcastReceiver
{

        @Override
        public void onReceive(Context context, Intent intent) 
        {
           Intent launchintent = new Intent();
           launchintent.setClassName(context, "com.embarcadero.firemonkey.FMXNativeActivity");           
           launchintent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
           context.startActivity(launchintent);  
        }

}