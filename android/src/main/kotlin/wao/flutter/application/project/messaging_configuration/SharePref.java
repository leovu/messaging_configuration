package wao.flutter.application.project.messaging_configuration;

import android.content.Context;
import android.content.SharedPreferences;

public class SharePref {
    private static SharePref sharePref;
    private SharedPreferences sharedPreferences;

    public static SharePref getInstance(Context context) {
        if (sharePref == null) {
            sharePref = new SharePref(context);
        }
        return sharePref;
    }

    private SharePref(Context context) {
        sharedPreferences = context.getSharedPreferences("SharePref",Context.MODE_PRIVATE);
    }

    public void saveData(String key,String value) {
        SharedPreferences.Editor prefsEditor = sharedPreferences.edit();
        prefsEditor .putString(key, value);
        prefsEditor.commit();
    }

    public String getData(String key) {
        if (sharedPreferences!= null) {
            return sharedPreferences.getString(key, "");
        }
        return "";
    }
}