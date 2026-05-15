//
//  AffirmationService.swift
//  MixFix
//
//  Daily affirmation generator based on mood
//

import Foundation

struct AffirmationService {
    
    // Calming affirmations for angry moods (1)
    private static let angryAffirmations = [
        "I am in control of my emotions, not the other way around.",
        "I am choosing peace over anger in this moment.",
        "I am releasing this frustration with every breath I take.",
        "I am bigger than this anger, and I can let it go.",
        "I am capable of responding with calm and clarity.",
        "I am transforming this energy into something positive.",
        "I am worthy of inner peace, even when things are hard.",
        "I am learning to pause before I react.",
        "I am strong enough to choose a different response.",
        "I am letting go of what I cannot control.",
        "I am breathing through this moment with patience.",
        "I am allowed to feel angry, but I choose not to let it control me.",
        "I am finding calm in the midst of this storm.",
        "I am channeling this intensity into productive action.",
        "I am choosing to respond with wisdom, not rage.",
        "I am releasing tension from my body and mind.",
        "I am grounded, centered, and in control.",
        "I am powerful when I choose peace over conflict.",
        "I am taking a step back to gain perspective.",
        "I am worthy of expressing my feelings in healthy ways."
    ]
    
    // Uplifting affirmations for sad moods (2)
    private static let sadAffirmations = [
        "I am bigger and stronger than my emotions.",
        "I am capable of moving through difficult feelings.",
        "I am resilient, and this moment will pass.",
        "I am worthy of compassion, especially from myself.",
        "I am learning and growing through challenges.",
        "I am allowed to feel this way, and I will be okay.",
        "I am stronger than I realize in this moment.",
        "I am taking it one step at a time, and that's enough.",
        "I am deserving of peace and calm.",
        "I am not defined by how I feel right now.",
        "I am brave for facing today.",
        "I am doing my best, and that is always enough.",
        "I am healing, even when it doesn't feel like it.",
        "I am worthy of support and understanding.",
        "I am capable of finding light in dark moments.",
        "I am gentle with myself during difficult times.",
        "I am surrounded by love, even when I can't feel it.",
        "I am honoring my feelings without judgment.",
        "I am moving through this darkness toward the light.",
        "I am worthy of comfort and care.",
        "I am choosing hope, even when it's hard.",
        "I am deserving of happiness and joy.",
        "I am proud of myself for showing up today.",
        "I am capable of creating better days ahead.",
        "I am worthy of all the good things coming my way.",
        "I am transforming pain into strength.",
        "I am opening my heart to healing and growth.",
        "I am brave enough to feel and brave enough to heal.",
        "I am surrounded by endless possibilities.",
        "I am worthy of a fresh start, right now.",
        "I am choosing to believe in better tomorrows.",
        "I am more powerful than any temporary sadness.",
        "I am deserving of moments that make me smile.",
        "I am creating space for joy to return.",
        "I am grateful for my courage to keep going."
    ]
    
    // Supportive affirmations for overwhelmed moods (3)
    private static let overwhelmedAffirmations = [
        "I am capable of handling one task at a time.",
        "I am breaking big challenges into small, doable steps.",
        "I am making progress, even when it feels slow.",
        "I am focusing on what's most important right now.",
        "I am stronger than this overwhelming feeling.",
        "I am taking action, even if it's just one small thing.",
        "I am doing my best, and that's moving me forward.",
        "I am capable of getting through this, step by step.",
        "I am prioritizing what truly matters today.",
        "I am releasing what I can't control and acting on what I can.",
        "I am building momentum with each task I complete.",
        "I am worthy of progress, not perfection.",
        "I am choosing to start somewhere, anywhere.",
        "I am capable of finishing what I start.",
        "I am turning overwhelm into action, one step at a time.",
        "I am powerful when I focus on one thing at a time.",
        "I am making space for what needs to be done.",
        "I am trusting myself to handle what's in front of me.",
        "I am taking control by taking the first step.",
        "I am capable of accomplishing more than I think.",
        "I am finding clarity by taking action.",
        "I am moving forward, even when it feels hard.",
        "I am choosing progress over perfection today.",
        "I am capable of managing my responsibilities.",
        "I am stronger with each small victory."
    ]
    
    // Calming affirmations for anxious moods (5)
    private static let anxiousAffirmations = [
        "I am safe in this moment, right here, right now.",
        "I am breathing through this anxiety with calm and control.",
        "I am bigger than my worries, and they will pass.",
        "I am grounding myself in the present moment.",
        "I am releasing thoughts that don't serve me.",
        "I am capable of handling whatever comes my way.",
        "I am choosing to focus on what I can control.",
        "I am letting go of what-ifs and embracing what is.",
        "I am worthy of peace and calm, even when anxious.",
        "I am taking this one breath, one moment at a time.",
        "I am stronger than my anxiety believes I am.",
        "I am allowed to feel anxious and still move forward.",
        "I am separating my thoughts from reality.",
        "I am trusting that this feeling will pass.",
        "I am not my anxiety; I am the one observing it.",
        "I am finding calm in the midst of uncertainty.",
        "I am gentle with myself during anxious moments.",
        "I am replacing fear with curiosity about what's next.",
        "I am grounding my feet on the earth and my mind in now.",
        "I am worthy of feeling safe and secure.",
        "I am acknowledging my anxiety without letting it control me.",
        "I am choosing courage over comfort.",
        "I am capable of sitting with discomfort until it passes.",
        "I am trusting my ability to navigate uncertainty.",
        "I am releasing tension from my body with each exhale.",
        "I am focusing on facts, not fears.",
        "I am allowed to ask for help when I need it.",
        "I am building resilience with every anxious moment I overcome.",
        "I am worthy of support and understanding.",
        "I am transforming nervous energy into productive action.",
        "I am reminding myself that feelings aren't facts.",
        "I am choosing to believe in positive outcomes.",
        "I am capable of calming my nervous system.",
        "I am finding peace in the uncertainty.",
        "I am trusting the process, even when it's uncomfortable."
    ]
    
    // Patience affirmations for annoyed moods
    private static let annoyedAffirmations = [
        "I am choosing patience over irritation.",
        "I am letting small annoyances roll off my shoulders.",
        "I am bigger than these minor frustrations.",
        "I am taking a deep breath and resetting my mindset.",
        "I am not letting little things steal my peace.",
        "I am responding with grace instead of annoyance.",
        "I am choosing to focus on what matters most.",
        "I am releasing this irritation with each exhale.",
        "I am in control of my reactions.",
        "I am finding humor in life's small inconveniences.",
        "I am preserving my energy for things that truly matter.",
        "I am practicing patience with myself and others.",
        "I am letting this moment pass without holding onto it.",
        "I am choosing calm over frustration.",
        "I am not allowing minor setbacks to derail my day.",
        "I am responding thoughtfully, not impulsively.",
        "I am maintaining my composure with ease.",
        "I am rising above these minor annoyances.",
        "I am keeping perspective on what's truly important.",
        "I am choosing peace over being right."
    ]
    
    // Motivational affirmations for drained moods (4) - empathetic but encouraging action
    private static let drainedAffirmations = [
        "I am tired, but I'm still capable of taking one small step forward.",
        "I am low on energy, but I can still accomplish something meaningful today.",
        "I am drained, but I'm choosing to do what I can with what I have.",
        "I am tired, yet I'm stronger than this temporary exhaustion.",
        "I am running low, but I'm not running out—I have more in me than I think.",
        "I am fatigued, but I'm still showing up and that takes courage.",
        "I am weary, but I'm pushing through because I know I can.",
        "I am exhausted, but I'm taking it one task at a time.",
        "I am drained, but I'm finding small bursts of energy to keep moving.",
        "I am tired, but I'm not giving up on today.",
        "I am low on fuel, but I'm making every bit count.",
        "I am worn out, but I'm still making progress, however small.",
        "I am fatigued, but I'm choosing action over surrender.",
        "I am drained, but I'm capable of finishing what I start.",
        "I am tired, but I'm building momentum with each small win.",
        "I am exhausted, but I'm not letting fatigue define my day.",
        "I am running low, but I'm prioritizing what matters most.",
        "I am weary, but I'm finding strength I didn't know I had.",
        "I am drained, but I'm taking strategic breaks to recharge and continue.",
        "I am tired, but I'm proving to myself that I can push through.",
        "I am low on energy, but I'm focusing on one thing at a time.",
        "I am fatigued, but I'm still capable of making today count.",
        "I am exhausted, but I'm choosing progress over perfection.",
        "I am drained, but I'm not defeated—I'm still moving forward.",
        "I am tired, but I'm using what little energy I have wisely.",
        "I am worn out, but I'm finding pockets of strength to keep going.",
        "I am fatigued, but I'm accomplishing more than I give myself credit for.",
        "I am drained, but I'm resilient and I will bounce back.",
        "I am tired, but I'm taking care of myself while still getting things done.",
        "I am low on energy, but I'm making smart choices about what to tackle.",
        "I am exhausted, but I'm not letting this stop me from trying.",
        "I am drained, but I'm building endurance with every effort I make.",
        "I am weary, but I'm capable of resting AND accomplishing.",
        "I am tired, but I'm finding balance between rest and action.",
        "I am fatigued, but I'm still in control of my day.",
        "I am drained, but I'm choosing to do something rather than nothing.",
        "I am exhausted, but I'm proud of myself for not giving up.",
        "I am low on energy, but I'm making today matter anyway.",
        "I am tired, but I'm proving that I'm stronger than my fatigue.",
        "I am drained, but I'm taking it step by step until I feel better."
    ]
    
    // Positive affirmations for happy moods (5)
    private static let happyAffirmations = [
        "I am radiating positive energy today.",
        "I am grateful for this feeling of joy.",
        "I am capable of achieving amazing things.",
        "I am creating momentum with my positive mindset.",
        "I am attracting good things into my life.",
        "I am making the most of this beautiful day.",
        "I am proud of how far I've come.",
        "I am spreading positivity to those around me.",
        "I am aligned with my goals and dreams.",
        "I am celebrating my wins, big and small.",
        "I am confident in my abilities.",
        "I am living with purpose and intention.",
        "I am grateful for this moment of happiness.",
        "I am building on this positive momentum.",
        "I am exactly where I want to be right now.",
        "I am embracing the good in my life.",
        "I am worthy of all the joy I'm feeling.",
        "I am sharing my light with the world.",
        "I am thriving in this moment.",
        "I am creating beautiful memories today."
    ]
    
    // Hopeful affirmations for okay moods (7)
    private static let okayAffirmations = [
        "I am open to better moments ahead.",
        "I am taking things one step at a time.",
        "I am finding peace in this neutral space.",
        "I am allowing myself to just be.",
        "I am grateful for stability and calm.",
        "I am building momentum slowly but surely.",
        "I am okay with where I am right now.",
        "I am trusting the process of my journey.",
        "I am finding small joys in ordinary moments.",
        "I am giving myself permission to feel neutral.",
        "I am steady and grounded today.",
        "I am appreciating the simple things.",
        "I am moving forward at my own pace.",
        "I am content with this moment of balance.",
        "I am finding clarity in the calm.",
        "I am honoring my current state.",
        "I am open to positive shifts.",
        "I am embracing this peaceful middle ground.",
        "I am building strength in stillness.",
        "I am trusting that better feelings will come."
    ]
    
    // Energized affirmations for very happy moods (9)
    private static let joyfulAffirmations = [
        "I am overflowing with gratitude and joy.",
        "I am unstoppable when I feel this good.",
        "I am living my best life right now.",
        "I am a magnet for amazing opportunities.",
        "I am celebrating this incredible feeling.",
        "I am sharing my happiness with everyone I meet.",
        "I am on fire with positive energy.",
        "I am achieving everything I set my mind to.",
        "I am blessed beyond measure.",
        "I am riding this wave of positivity.",
        "I am creating magic in my life.",
        "I am shining brightly today.",
        "I am grateful for this abundance of joy.",
        "I am inspiring others with my energy.",
        "I am living in alignment with my highest self.",
        "I am making incredible things happen.",
        "I am exactly where I'm meant to be.",
        "I am embracing this beautiful moment fully.",
        "I am radiating love and light.",
        "I am grateful for this amazing day."
    ]
    
    static func getDailyAffirmation(basedOnMood mood: Int?) -> String {
        let calendar = Calendar.current
        let today = Date()
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        return getAffirmation(basedOnMood: mood, index: dayOfYear - 1)
    }
    
    static func getAffirmation(basedOnMood mood: Int?, index: Int) -> String {
        // Select affirmation category based on mood
        let affirmations: [String]
        if let mood = mood {
            switch mood {
            case 1: // Angry
                affirmations = angryAffirmations
            case 2: // Sad
                affirmations = sadAffirmations
            case 3: // Overwhelmed
                affirmations = overwhelmedAffirmations
            case 4: // Drained
                affirmations = drainedAffirmations
            case 5: // Anxious
                affirmations = anxiousAffirmations
            case 6: // Annoyed
                affirmations = annoyedAffirmations
            case 7: // Okay
                affirmations = okayAffirmations
            case 8: // Good
                affirmations = happyAffirmations
            case 9: // Amazing
                affirmations = joyfulAffirmations
            default:
                affirmations = happyAffirmations
            }
        } else {
            // No mood logged yet, use happy affirmations
            affirmations = happyAffirmations
        }
        
        // Use index to select an affirmation, cycling through the array
        let affirmationIndex = index % affirmations.count
        return affirmations[affirmationIndex]
    }
}
