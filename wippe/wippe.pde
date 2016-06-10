#include <Arduino.h>

/* Defines */
#define T_PWM           280000      /* Alle 7 ms */
#define T_PWM_MIN       27000
#define T_PWM_MAX       73000
#define T_PWM_MIDDLE    48000
#define T_CTRL          4000       /* Alle 100µs */

#define ANALOG_IN   14
#define PWM_OUT 9


/* Funktions Prototypen */
uint32_t pwm_callback(uint32_t currentTime);
uint32_t ctrl_callback(uint32_t currentTime);
void get_position(void);
void set_pw(uint16_t pw);



/* Globale Variablen */
uint32_t u32_pw;        /* Pulsbreite für die Stellung der Wippe */
int32_t i32_position;   /* Position der Kugel in 10^-5 m */
int32_t p_value;        /* P-Wert für den Regler */



void setup(void)
{
    u32_pw = T_PWM_MIN;  /* Mittelstellung */
    
    pinMode(PWM_OUT, OUTPUT);
    pinMode(ANALOG_IN, INPUT);
    Serial.begin(9600);
    
    attachCoreTimerService(pwm_callback);
    attachCoreTimerService(ctrl_callback);
    p_value = 30;   /* Experimentel ermittelter P-Wert für den Regler */
    
}


void loop(void)
{
    Serial.print( ((float)i32_position) /10);
    Serial.print(" mm\n");
    Serial.println(u32_pw);
    Serial.println(" ");
    delay(500);
}


/* Funktion für die Generierung eines Pulsbreiten Modulierten Signals */
/* Sie wird als Callback-Funktion eines Core-Timer verwendet */
uint32_t pwm_callback(uint32_t currentTime)
{
    static bool last = true;
    uint32_t u32_return;
    
    digitalWrite(PWM_OUT, last);
    
    if(last)
        u32_return = u32_pw + currentTime;
    else
        u32_return = currentTime + (T_PWM - u32_pw);
    
    last = !last;
    
    return u32_return;
}

/* Funktion die einen Regler beinhaltet */
/* Sie wird als Callback-Funktion eines Core-Timer verwendet */
uint32_t ctrl_callback(uint32_t currentTime)
{   
    int32_t i32_Pterm, i32_error;
    
    /* Position bestimmen */
    get_position();
    
    /* Abweichung berechnen */
    i32_error = 0 - i32_position;
    
    i32_Pterm = i32_error * p_value;
    
    i32_Pterm += T_PWM_MIDDLE;
    set_pw((uint32_t) i32_Pterm);
    
    return (currentTime + T_CTRL);
}


/* Funktion um die Position der Kugel zu bestimmen */
/* Sie ließt den AD-Wandler aus und berechnet daraus die Position */
void get_position(void)
{
    uint16_t u16_adc;
    
    /* Aktuellen Wert Messen */
    u16_adc = analogRead(ANALOG_IN);
    
    /* Position berechnen */
    i32_position = 2000 * (3*u16_adc-1024) /(2*u16_adc+2048); 
}


/* Funktion um die Pulsbreite einzustellen */
/* Wird ein Wert der größer ist als das ermittetlte Maximum oder kleiner als das Minimum */
/* wird dieser begränzt */
void set_pw(uint32_t pw)
{
    if(pw > T_PWM_MAX)
        u32_pw = T_PWM_MAX;
    else if(pw < T_PWM_MIN)
        u32_pw = T_PWM_MIN;
    else
        u32_pw = pw;
}
