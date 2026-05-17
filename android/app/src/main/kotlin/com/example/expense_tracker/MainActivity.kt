package com.example.expense_tracker

import io.flutter.embedding.android.FlutterFragmentActivity

// 必須繼承 FlutterFragmentActivity，否則 local_auth 的 BiometricPrompt 會閃退/無反應
class MainActivity : FlutterFragmentActivity()
