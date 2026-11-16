package com.follow.clash.common

import android.content.ComponentName

object Components {
    private const val CLASS_PACKAGE = "com.follow.clash"
    const val PACKAGE_NAME = "com.youkomix.client"

    val mainActivity =
        ComponentName(GlobalState.packageName, "$CLASS_PACKAGE.MainActivity")

    val quickActionActivity =
        ComponentName(GlobalState.packageName, "$CLASS_PACKAGE.QuickActionActivity")

    val serviceBroadcastReceiver =
        ComponentName(GlobalState.packageName, "$CLASS_PACKAGE.ServiceBroadcastReceiver")
}
