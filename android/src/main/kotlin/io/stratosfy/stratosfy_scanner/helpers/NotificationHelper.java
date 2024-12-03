package io.stratosfy.stratosfy_scanner.helpers;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;


import io.stratosfy.stratosfy_scanner.R;

import java.util.Random;

public class NotificationHelper {
    static void createNotificationChannel(Context context, String channelName) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            int importance = NotificationManager.IMPORTANCE_DEFAULT;
            NotificationChannel channel = new NotificationChannel(channelName, channelName, importance);
            channel.setDescription(channelName);
            NotificationManager notificationManager = context.getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);
        }
    }

    public static void sendNotification(Integer id, String channelName, Context context, String title, String content, boolean sticky) {
        if (id == null) id = new Random().nextInt();
        createNotificationChannel(context, channelName);

        PendingIntent contentIntent = PendingIntent.getActivity(context, 0, new Intent(Intent.ACTION_VIEW), PendingIntent.FLAG_UPDATE_CURRENT);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, "snowm_scanner")
                .setAutoCancel(true)
                .setContentTitle(title)
                .setContentText(content)

                .setContentIntent(contentIntent)
                .setSmallIcon(R.drawable.skel_logo)
                .setWhen(System.currentTimeMillis())
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setStyle(new NotificationCompat.BigTextStyle().bigText(content));
        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(context);

        Notification notification = builder.build();
        if (sticky)
            notification.flags |= Notification.FLAG_NO_CLEAR | Notification.FLAG_ONGOING_EVENT;
        notificationManager.notify(id, notification);
    }

    public static void removeNotification(Context context, int id) {
        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(context);
        notificationManager.cancel(id);
    }

}
