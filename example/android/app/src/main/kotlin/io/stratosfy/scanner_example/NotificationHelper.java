package io.stratosfy.scanner_example;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;

import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

import io.stratosfy.stratosfy_scanner.services.SnowMBackgroundScanningService;
import io.stratosfy.stratosfy_scanner.models.SnowMiBeacon;
import io.stratosfy.stratosfy_scanner.R;

import java.util.ArrayList;
import java.util.Random;

class NotificationHelper {
    static void createNotificationChannel(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            int importance = NotificationManager.IMPORTANCE_DEFAULT;
            NotificationChannel channel = new NotificationChannel("snowm_scanner", "Snowm Scanner channel", importance);
            channel.setDescription("Notification alerts for snowm scanner.");
            NotificationManager notificationManager = context.getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);
        }
    }

    static void sendNotification(Integer id, Context context, String title, String content, Intent intent) {
        if (id == null) id = new Random().nextInt();
        createNotificationChannel(context);

        PendingIntent contentIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, "snowm_scanner")
                .setSmallIcon(R.drawable.skel_logo)
                .setContentTitle(title)
                .setWhen(System.currentTimeMillis())
                .setAutoCancel(true)
                .setContentIntent(contentIntent)
                .setStyle(new NotificationCompat.BigTextStyle().bigText(content))
                .setContentText(content)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT);
        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(context);

        notificationManager.notify(id, builder.build());
    }

}
