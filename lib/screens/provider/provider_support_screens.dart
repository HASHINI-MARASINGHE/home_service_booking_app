import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/locale_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

// ============================================================================
// 1. PROVIDER HELP & SUPPORT SCREEN
// ============================================================================

class ProviderHelpSupportScreen extends StatelessWidget {
  const ProviderHelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final code = LocaleController.instance.locale.languageCode;
        final isSinhala = code == 'si';
        final isTamil = code == 'ta';

        final pageTitle = isTamil
            ? 'உதவி மற்றும் ஆதரவு'
            : (isSinhala ? 'උදව් සහ සහාය' : 'Help & Support');
        final headerTitle = isTamil
            ? 'வழங்குநர் வழிகாட்டி மற்றும் உதவி'
            : (isSinhala ? 'සේවා සපයන්නන්ගේ මාර්ගෝපදේශ' : 'Provider Knowledge & Guides');
        final headerSubtitle = isTamil
            ? 'பொதுவான கேள்விகளுக்கான பதில்கள் மற்றும் தொழில்முறை வழிகாட்டிகள்.'
            : (isSinhala
                ? 'නිතර අසන ප්‍රශ්න සහ වෘත්තීය සේවා මාර්ගෝපදේශ.'
                : 'Browse FAQs and expert tips to grow your service career on HomeCare.');

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            foregroundColor: AppColors.brand900,
            elevation: 0,
            title: Text(
              pageTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.md,
              ),
              children: [
                _HeaderCard(
                  icon: LucideIcons.circleHelp,
                  title: headerTitle,
                  subtitle: headerSubtitle,
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle(
                  title: isTamil
                      ? 'அடிக்கடி கேட்கப்படும் கேள்விகள்'
                      : (isSinhala ? 'නිතර අසන පැනයන්' : 'Frequently Asked Questions'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _FaqAccordion(
                  question: isTamil
                      ? 'புதிய வேலை வாய்ப்புகளை ஏற்றுக்கொள்வது எப்படி?'
                      : (isSinhala
                          ? 'නව සේවා ඇණවුම් (Job Leads) භාරගන්නේ කෙසේද?'
                          : 'How do I accept new job leads?'),
                  answer: isTamil
                      ? 'உங்கள் Leads தாவலில் புதிய வேலை அறிவிப்புகள் தோன்றும். விவரங்களைச் சரிபார்த்து "Accept Job" என்பதை அழுத்தவும்.'
                      : (isSinhala
                          ? 'ඔබේ Leads tab එකට නව සේවා ඉල්ලීම් ලැබෙනු ඇත. විස්තර පරීක්ෂා කර "Accept Job" බොත්තම ඔබන්න. පාරිභෝගිකයා සමඟ සෘජුව සම්බන්ධ වී වේලාව තහවුරු කරන්න.'
                          : 'Navigate to your Leads tab to view incoming job requests. Review customer requirements and location, then tap "Accept Job" to claim the request.'),
                ),
                _FaqAccordion(
                  question: isTamil
                      ? 'வருமானம் மற்றும் பணம் எவ்வாறு செலுத்தப்படும்?'
                      : (isSinhala
                          ? 'ආදායම් සහ ගෙවීම් (Payouts) ලැබෙන්නේ කෙසේද?'
                          : 'How do earnings & payouts work?'),
                  answer: isTamil
                      ? 'வேலை முடிந்ததும் கட்டணம் உங்கள் கணக்கில் சேரும். வாரந்தோறும் உங்கள் வங்கிக் கணக்கிற்கு பணம் மாற்றப்படும்.'
                      : (isSinhala
                          ? 'සේවාව අවසන් වූ පසු පාරිභෝගිකයා ගෙවන මුදල් ඔබේ HomeCare ගිණුමට බැර වේ. සෑම සතියකම හෝ ඉල්ලීම මත ඔබේ බැංකු ගිණුමට මුදල් තැන්පත් කරනු ලැබේ.'
                          : 'Job earnings are credited immediately upon customer completion sign-off. Payouts are transferred automatically to your registered bank account on a regular schedule.'),
                ),
                _FaqAccordion(
                  question: isTamil
                      ? 'சரிபார்ப்பு (Verification) பெறுவது எப்படி?'
                      : (isSinhala
                          ? 'ගිණුම Verify (තහවුරු) කරගන්නේ කෙසේද?'
                          : 'How do I get my Verified Provider badge?'),
                  answer: isTamil
                      ? 'உங்கள் தேசிய அடையாள அட்டை, தொழில் சான்றிதழ் மற்றும் செல்பி ஆகியவற்றை பதிவேற்றி சமர்ப்பிக்கவும். நிர்வாகி சரிபார்த்து அங்கீகரிப்பார்.'
                      : (isSinhala
                          ? 'ඔබේ ජාතික හැඳුනුම්පත, සෙල්ෆි ඡායාරූපය සහ වෘත්තීය සහතික Profile එක හරහා Upload කරන්න. අපේ admin කණ්ඩායම පැය 24ක් තුළ ඒවා පරීක්ෂා කර Provider ID එක නිකුත් කරයි.'
                          : 'Upload your National ID / Passport, a live photo, and vocational training certificates in your profile. Our verification team reviews submissions within 24 hours.'),
                ),
                _FaqAccordion(
                  question: isTamil
                      ? 'வாடிக்கையாளர் சர்ச்சையை (Dispute) திறந்தால் என்ன செய்வது?'
                      : (isSinhala
                          ? 'පාරිභෝගිකයෙකු Dispute එකක් ඉදිරිපත් කළහොත් කුමක් කළ යුතුද?'
                          : 'What happens if a customer opens a dispute?'),
                  answer: isTamil
                      ? 'My Disputes பக்கத்திற்குச் சென்று விவரங்களைப் பார்க்கலாம். நியாயமான தீர்வுக்காக எங்கள் ஆதரவு குழு உங்களுடன் தொடர்பு கொள்ளும்.'
                      : (isSinhala
                          ? 'My Disputes පිටුවෙන් ඔබට අදාළ dispute එක පරීක්ෂා කර පිළිතුරු දිය හැක. අපේ විනිශ්චය කණ්ඩායම සාධාරණ විසඳුමක් සඳහා දෙපාර්ශවයම අමතනු ඇත.'
                          : 'Visit your "My Disputes" page to view complaint details and submit your statement or photos. Our resolution specialists will mediate fairly according to policy.'),
                ),
                _FaqAccordion(
                  question: isTamil
                      ? 'எனது தரவரிசையை (Rating) அதிகரிப்பது எப்படி?'
                      : (isSinhala
                          ? 'මගේ Rating එක ඉහළ නංවා ගන්නේ කෙසේද?'
                          : 'How can I improve my overall rating?'),
                  answer: isTamil
                      ? 'சரியான நேரத்திற்குச் செல்லுதல், நேர்மையான விலை மற்றும் தரமான சேவை ஆகியவை உங்கள் மதிப்பீட்டை உயர்த்தும்.'
                      : (isSinhala
                          ? 'නියමිත වේලාවට පැමිණීම, මිත්‍රශීලී සන්නිවේදනය, උසස් වැඩ නිමාව සහ නිවැරදි මිල අය කිරීම මඟින් තරු 5 Rating ලබාගත හැක.'
                          : 'Punctuality, clear communication, neat workmanship, and polite customer engagement are key factors for achieving 5-star customer ratings.'),
                ),
                const SizedBox(height: AppSpacing.lg),
                _HelpContactBanner(
                  isSinhala: isSinhala,
                  isTamil: isTamil,
                  onContactTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProviderContactSupportScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// 2. PROVIDER CONTACT SUPPORT SCREEN
// ============================================================================

class ProviderContactSupportScreen extends StatelessWidget {
  const ProviderContactSupportScreen({super.key});

  Future<void> _makeCall(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final code = LocaleController.instance.locale.languageCode;
        final isSinhala = code == 'si';
        final isTamil = code == 'ta';

        final pageTitle = isTamil
            ? 'ஆதரவை தொடர்பு கொள்ளவும்'
            : (isSinhala ? 'සහාය සේවාව අමතන්න' : 'Contact Support');

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            foregroundColor: AppColors.brand900,
            elevation: 0,
            title: Text(
              pageTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.md,
              ),
              children: [
                _HeaderCard(
                  icon: LucideIcons.headset,
                  title: isTamil
                      ? 'வழங்குநர் ஆதரவு மையம்'
                      : (isSinhala ? 'ක්ෂණික සහායක සේවාව' : 'Provider Care Helpdesk'),
                  subtitle: isTamil
                      ? 'உங்களுக்கு உதவ எங்கள் பிரத்யேக ஆதரவு குழு எப்போதும் தயாராக உள்ளது.'
                      : (isSinhala
                          ? 'ඔබට සහාය වීමට අපගේ කණ්ඩායම දිනපතා සූදානමින් සිටී.'
                          : 'Our dedicated provider operations team is available 7 days a week.'),
                ),
                const SizedBox(height: AppSpacing.lg),
                _ContactActionCard(
                  icon: LucideIcons.phoneCall,
                  badge: isTamil ? 'இலவசம்' : (isSinhala ? 'ගාස්තු රහිත' : 'Toll-Free'),
                  title: isTamil ? 'நேரடி அழைப்பு 1344' : (isSinhala ? 'ක්ෂණික ඇමතුම් 1344' : 'Hotline 1344'),
                  subtitle: isTamil
                      ? 'காலை 7:00 முதல் இரவு 10:00 வரை'
                      : (isSinhala ? 'දිනපතා පෙ.ව. 7:00 – ප.ව. 10:00' : 'Daily 7:00 AM – 10:00 PM'),
                  actionLabel: isTamil ? 'அழைக்கவும்' : (isSinhala ? 'අමතන්න' : 'Call 1344'),
                  onTap: () => _makeCall('1344'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ContactActionCard(
                  icon: LucideIcons.phone,
                  badge: 'Direct Desk',
                  title: '+94 11 234 5678',
                  subtitle: isTamil
                      ? 'வழங்குநர் நேரடி உதவி எண்'
                      : (isSinhala ? 'සැපයුම්කරු කාර්යාල ඇමතුම්' : 'Provider Operations Desk'),
                  actionLabel: isTamil ? 'அழைக்கவும்' : (isSinhala ? 'අමතන්න' : 'Call Now'),
                  onTap: () => _makeCall('+94112345678'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ContactActionCard(
                  icon: LucideIcons.mail,
                  badge: 'Email',
                  title: 'partners@homecare.app',
                  subtitle: isTamil
                      ? 'வணிக மற்றும் கட்டண உதவிகள்'
                      : (isSinhala ? 'ගෙවීම් සහ ගිණුම් විමසීම්' : 'Payouts & account assistance'),
                  actionLabel: isTamil ? 'மின்னஞ்சல்' : (isSinhala ? 'ඊමේල් කරන්න' : 'Send Email'),
                  onTap: () => _sendEmail('partners@homecare.app'),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle(
                  title: isTamil
                      ? 'செயல்பாட்டு நேரம் மற்றும் இடம்'
                      : (isSinhala ? 'සේවා කාලසීමාව සහ ලිපිනය' : 'Operations & Location'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.card,
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Column(
                    children: [
                      _DetailRowItem(
                        icon: LucideIcons.clock,
                        label: isTamil ? 'வேலை நேரம்' : (isSinhala ? 'සේවා වේලාවන්' : 'Working Hours'),
                        value: 'Mon – Sun: 7:00 AM – 10:00 PM',
                      ),
                      const Divider(height: 24, color: AppColors.borderSubtle),
                      _DetailRowItem(
                        icon: LucideIcons.shieldAlert,
                        label: isTamil ? 'அவசர உதவி' : (isSinhala ? 'හදිසි ආරවුල්' : 'Emergency Line'),
                        value: '24/7 Priority Support for active jobs',
                      ),
                      const Divider(height: 24, color: AppColors.borderSubtle),
                      _DetailRowItem(
                        icon: LucideIcons.mapPin,
                        label: isTamil ? 'தலைமையகம்' : (isSinhala ? 'ප්‍රධාන කාර්යාලය' : 'Head Office'),
                        value: 'Level 4, HomeCare Partner Center, Galle Road, Colombo 03',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// 3. PROVIDER TERMS & CONDITIONS SCREEN
// ============================================================================

class ProviderTermsScreen extends StatelessWidget {
  const ProviderTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final code = LocaleController.instance.locale.languageCode;
        final isSinhala = code == 'si';
        final isTamil = code == 'ta';

        final pageTitle = isTamil
            ? 'விதிமுறைகள் மற்றும் நிபந்தනைகள்'
            : (isSinhala ? 'නියමයන් සහ කොන්දේසි' : 'Terms & Conditions');

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            foregroundColor: AppColors.brand900,
            elevation: 0,
            title: Text(
              pageTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.md,
              ),
              children: [
                _HeaderCard(
                  icon: LucideIcons.fileCheck,
                  title: isTamil
                      ? 'சேவை வழங்குநர் ஒப்பந்தம்'
                      : (isSinhala ? 'සේවා සැපයුම්කරු ගිවිසුම' : 'Provider Service Agreement'),
                  subtitle: isTamil
                      ? 'கடைசியாக புதுப்பிக்கப்பட்டது: அக்டோபர் 2026'
                      : (isSinhala
                          ? 'අවසන් වරට යාවත්කාලීන කළේ: ඔක්තෝබර් 2026'
                          : 'Effective Date: October 2026 · Version 2.4'),
                ),
                const SizedBox(height: AppSpacing.lg),
                _LegalClauseCard(
                  number: '01',
                  title: isTamil
                      ? 'தகுதி மற்றும் கணக்கு சரிபார்ப்பு'
                      : (isSinhala ? 'සුදුසුකම් සහ ගිණුම් සත්‍යාපනය' : 'Eligibility & Verification'),
                  content: isTamil
                      ? 'சேவை வழங்குநர்கள் செல்லுபடியாகும் தேசிய அடையாள அட்டை, தூய்மையான பின்னணி மற்றும் தொழில் சான்றிதழ்களை வைத்திருக்க வேண்டும்.'
                      : (isSinhala
                          ? 'HomeCare සේවාව සැපයීමට වලංගු ජාතික හැඳුනුම්පතක් හෝ විදේශ ගමන් බලපත්‍රයක්, අපරාධ වාර්තා රහිත බව සහ නිසි වෘත්තීය සහතික තිබීම අනිවාර්ය වේ. අසත්‍ය තොරතුරු ලබාදීමෙන් ගිණුම අවලංගු විය හැක.'
                          : 'Partners must submit a valid National Identity Card or Passport, verified background records, and recognized vocational qualifications. Providing fraudulent details results in immediate termination.'),
                ),
                _LegalClauseCard(
                  number: '02',
                  title: isTamil
                      ? 'சேவை தரம் மற்றும் நடத்தை'
                      : (isSinhala ? 'සේවා ප්‍රමිතීන් සහ වෘත්තීය ආචාරධර්ම' : 'Service Standards & Conduct'),
                  content: isTamil
                      ? 'நேரத்திற்கு செல்லுதல், பாதுகாப்பு உபகரணங்களை அணிதல் மற்றும் வாடிக்கையாளர்களிடம் மரியாதையுடன் பழகுவது கட்டாயமாகும்.'
                      : (isSinhala
                          ? 'නියමිත වේලාවට සේවා ස්ථානයට පැමිණීම, සුදුසු ආරක්ෂිත ඇඳුම් හා මෙවලම් භාවිතය සහ පාරිභෝගිකයින් සමඟ ගෞරවනීයව කටයුතු කිරීම අනිවාර්ය වේ. අක්‍රමවත් ලෙස හැසිරීම හෝ ප්‍රමාදවීම දඬුවම් ලැබිය හැකි වරදකි.'
                          : 'Providers must maintain exemplary workmanship, arrive promptly, use appropriate safety gear, and treat customers with professionalism and respect at all times.'),
                ),
                _LegalClauseCard(
                  number: '03',
                  title: isTamil
                      ? 'கட்டணம் மற்றும் கமிஷன்'
                      : (isSinhala ? 'මිල නියම කිරීම සහ ගෙවීම් කොමිස්' : 'Pricing, Commission & Payouts'),
                  content: isTamil
                      ? 'வேலை முடிந்ததும் கட்டணம் கணக்கிடப்படும். பிளாட்பார்ம் கமிஷன் கழித்த பின் முழுத் தொகையும் உங்கள் வங்கிக் கணக்கில் வரவு வைக்கப்படும்.'
                      : (isSinhala
                          ? 'සියලුම සේවා ගාස්තු විනිවිදභාවයෙන් යුතුව සටහන් කළ යුතුය. එකඟ වූ වේදිකා කොමිස් මුදල අඩු කිරීමෙන් පසු නියමිත කාලසීමාව තුළ ඔබේ ලියාපදිංචි බැංකු ගිණුමට ඉපැයීම් බැර කරනු ලැබේ.'
                          : 'Agreed platform service fees are deducted upon successful completion. Remaining net earnings are disbursed straight to your validated bank account according to the payout schedule.'),
                ),
                _LegalClauseCard(
                  number: '04',
                  title: isTamil
                      ? 'ரத்துசெய்தல் கொள்கை'
                      : (isSinhala ? 'අවලංගු කිරීමේ ප්‍රතිපත්තිය' : 'Cancellations & No-Show Policy'),
                  content: isTamil
                      ? 'ஏற்றுக்கொண்ட வேலையை நியாயமான காரணமின்றி ரத்து செய்ய முடியாது. அவசர காரணங்களை முன்கூட்டியே தெரிவிக்க வேண்டும்.'
                      : (isSinhala
                          ? 'භාරගත් ඇණවුමක් අත්‍යවශ්‍ය හේතුවක් නොමැතිව අවලංගු කළ නොහැක. හදිසි අවස්ථාවකදී අවම වශයෙන් පැය 3කට පෙර පාරිභෝගිකයාට සහ සහායක කණ්ඩායමට දැනුම් දිය යුතුය.'
                          : 'Accepted bookings must be honored. In inevitable emergencies, notify support at least 3 hours prior. Unexcused cancellations or no-shows lower provider reliability scores.'),
                ),
                _LegalClauseCard(
                  number: '05',
                  title: isTamil
                      ? 'நேரடி பரிவர்த்தனைகள் தடை'
                      : (isSinhala ? 'පද්ධතියෙන් බැහැර සේවා සැපයීම තහනම් කිරීම' : 'Direct Dealing Prohibition'),
                  content: isTamil
                      ? 'HomeCare வாடிக்கையாளர்களுடன் செயலிக்கு வெளியே தனிப்பட்ட முறையில் பணப் பரிவர்த்தனை செய்வது தடைசெய்யப்பட்டுள்ளது.'
                      : (isSinhala
                          ? 'HomeCare හරහා හඳුනාගත් පාරිභෝගිකයින්ගෙන් යෙදුමට පිටතින් පුද්ගලිකව මුදල් අය කිරීම හෝ සේවා සැපයීම සපුරා තහනම් වේ. මෙය උල්ලංඝනය කිරීමෙන් ගිණුම ස්ථිරවම අක්‍රිය කරනු ඇත.'
                          : 'Soliciting direct offline payments or circumventing the HomeCare platform with customers met via the app is strictly prohibited and leads to immediate account ban.'),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// 4. PROVIDER PRIVACY POLICY SCREEN
// ============================================================================

class ProviderPrivacyPolicyScreen extends StatelessWidget {
  const ProviderPrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final code = LocaleController.instance.locale.languageCode;
        final isSinhala = code == 'si';
        final isTamil = code == 'ta';

        final pageTitle = isTamil
            ? 'தனியுரிமைக் கொள்கை'
            : (isSinhala ? 'පෞද්ගලිකත්ව ප්‍රතිපත්තිය' : 'Privacy Policy');

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            foregroundColor: AppColors.brand900,
            elevation: 0,
            title: Text(
              pageTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.md,
              ),
              children: [
                _HeaderCard(
                  icon: LucideIcons.shieldCheck,
                  title: isTamil
                      ? 'வழங்குநர் தரவு பாதுகாப்பு'
                      : (isSinhala ? 'දත්ත සහ පෞද්ගලිකත්ව ආරක්ෂාව' : 'Provider Data Protection'),
                  subtitle: isTamil
                      ? 'உங்கள் தனிப்பட்ட மற்றும் நிதி விவரங்களை நாங்கள் எவ்வாறு பாதுகாக்கிறோம்.'
                      : (isSinhala
                          ? 'ඔබේ පුද්ගලික තොරතුරු සහ ගිණුම් දත්ත අපි සුරක්ෂිතව තබාගන්නා ආකාරය.'
                          : 'How HomeCare safeguards your identity, location, and banking details.'),
                ),
                const SizedBox(height: AppSpacing.lg),
                _LegalClauseCard(
                  number: '01',
                  title: isTamil
                      ? 'நாங்கள் சேகரிக்கும் தகவல்கள்'
                      : (isSinhala ? 'අප රැස්කරන තොරතුරු' : 'Information We Collect'),
                  content: isTamil
                      ? 'பெயர், தொலைபேසි எண், அடையாள அட்டை விவரங்கள், புகைப்படங்கள் மற்றும் வங்கி கணக்கு விபரங்கள் கணக்கு சரிபார்ப்புக்கு சேகரிக்கப்படும்.'
                      : (isSinhala
                          ? 'ඔබේ සම්පූර්ණ නම, ඊමේල්, දුරකථන අංකය, ජාතික හැඳුනුම්පත් ඡායාරූප, සෙල්ෆි පින්තූර සහ ගෙවීම් සඳහා බැංකු ගිණුම් විස්තර ගිණුම තහවුරු කරගැනීමට පමණක් රැස්කරනු ලැබේ.'
                          : 'We collect your full name, email, phone number, national verification records, selfie photo, and bank account credentials exclusively for identity validation and payouts.'),
                ),
                _LegalClauseCard(
                  number: '02',
                  title: isTamil
                      ? 'இருப்பிடத் தகவல் (Location Data)'
                      : (isSinhala ? 'ස්ථාන තොරතුරු (GPS Location)' : 'GPS & Location Tracking'),
                  content: isTamil
                      ? 'நீங்கள் ஆன்லைனில் இருக்கும் போது மற்றும் செயலில் உள்ள வேலைக்கு செல்லும் போது மட்டுமே இருப்பிடம் கண்காணிக்கப்படும். ஆஃப்லைனில் இருக்கும் போது கண்காணிக்கப்படாது.'
                      : (isSinhala
                          ? 'ඔබ සේවා සඳහා "Available" වී සිටින විට සහ ක්‍රියාකාරී ඇණවුමක් වෙත ගමන් කරන විට පමණක් GPS පිහිටීම ලබාගැනේ. Offline වූ විට ස්ථාන තොරතුරු ලබාගැනීම සම්පූර්ණයෙන්ම නතර වේ.'
                          : 'Your real-time location is captured exclusively when you are toggled available or navigating to an active booking dispatch. Location access halts when offline.'),
                ),
                _LegalClauseCard(
                  number: '03',
                  title: isTamil
                      ? 'வாடிக்கையாளர் தரவு பாதுகாப்பு'
                      : (isSinhala ? 'පාරිභෝගික දත්ත සුරැකීම' : 'Customer Data Confidentiality'),
                  content: isTamil
                      ? 'வேலையை முடிக்க மட்டுமே வாடிக்கையாளரின் தொலைபேசி மற்றும் முகவரி வழங்கப்படும். அதை சேமிக்கவோ தவறாகப் பயன்படுத்தவோ கூடாது.'
                      : (isSinhala
                          ? 'පාරිභෝගිකයාගේ දුරකථන අංකය සහ ලිපිනය ඔබට පෙනෙන්නේ සේවාව ඉටුකිරීම සඳහා පමණි. එම දත්ත සුරැකීම, වෙනත් පාර්ශවයකට ලබාදීම හෝ අනිසි ලෙස භාවිතා කිරීම තහනම් වේ.'
                          : 'Customer contact and address details are revealed strictly for fulfilling the active service. Exporting, saving, or misusing customer details is grounds for legal action.'),
                ),
                _LegalClauseCard(
                  number: '04',
                  title: isTamil
                      ? 'வங்கி மற்றும் நிதி பாதுகாப்பு'
                      : (isSinhala ? 'බැංකු සහ ගිණුම් ආරක්ෂාව' : 'Financial & Bank Security'),
                  content: isTamil
                      ? 'அனைத்து நிதி பரிவர்த்தனைகளும் 256-bit குறியாக்கத்துடன் (Encryption) மிகவும் பாதுகாப்பாக கையாளப்படுகின்றன.'
                      : (isSinhala
                          ? 'ඔබේ බැංකු ගිණුම් තොරතුරු 256-bit AES encryption තාක්ෂණයෙන් ආරක්ෂා කර ඇති අතර මූල්‍ය ආරක්ෂක ප්‍රමිතීන්ට අනුකූලව පවත්වාගෙන යනු ලැබේ.'
                          : 'Bank account and payout details are encrypted with bank-grade 256-bit encryption in full compliance with regulated financial data standards.'),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// SHARED HELPER WIDGETS
// ============================================================================

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brand100,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.brand700, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.brand900,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.ink3,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.brand900,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _FaqAccordion extends StatefulWidget {
  const _FaqAccordion({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  State<_FaqAccordion> createState() => _FaqAccordionState();
}

class _FaqAccordionState extends State<_FaqAccordion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: AppRadius.card,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    color: AppColors.ink3,
                    size: 18,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                Text(
                  widget.answer,
                  style: const TextStyle(
                    color: AppColors.ink3,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpContactBanner extends StatelessWidget {
  const _HelpContactBanner({
    required this.isSinhala,
    required this.isTamil,
    required this.onContactTap,
  });

  final bool isSinhala;
  final bool isTamil;
  final VoidCallback onContactTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.brand50,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.brand100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.brand700,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.phone, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTamil
                      ? 'மேலும் உதவி தேவையா?'
                      : (isSinhala ? 'තවත් සහාය අවශ්‍යද?' : 'Need more help?'),
                  style: const TextStyle(
                    color: AppColors.brand900,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isTamil
                      ? 'எங்கள் ஆதரவு குழுவை உடனே தொடர்பு கொள்ளவும்'
                      : (isSinhala ? 'අපේ සහායක කණ්ඩායම අමතන්න' : 'Reach our provider care desk directly'),
                  style: const TextStyle(
                    color: AppColors.ink3,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onContactTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
            ),
            child: Text(
              isTamil ? 'அழைக்கவும்' : (isSinhala ? 'අමතන්න' : 'Contact'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactActionCard extends StatelessWidget {
  const _ContactActionCard({
    required this.icon,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String badge;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brand100,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.brand700, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.brand50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: AppColors.brand700,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.ink3,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brand700,
              side: const BorderSide(color: AppColors.brand700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRowItem extends StatelessWidget {
  const _DetailRowItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.brand700, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.ink3,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegalClauseCard extends StatelessWidget {
  const _LegalClauseCard({
    required this.number,
    required this.title,
    required this.content,
  });

  final String number;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brand100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: AppColors.brand700,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.brand900,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
