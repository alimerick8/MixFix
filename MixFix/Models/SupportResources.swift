//
//  SupportResources.swift
//  MixFix
//
//  Support toolkit resources for low mood support
//

import Foundation

struct SupportCategory: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let items: [String]
    let color: String // Hex color
}

struct SupportToolkit {
    static let categories: [SupportCategory] = [
        SupportCategory(
            icon: "bolt.fill",
            title: "⭐ Fastest Relief (Low-Effort, Immediate)",
            subtitle: "Quick actions for immediate relief",
            items: [
                "Blast music with headphones — bonus: sing or scream into a pillow",
                "Hold an ice cube and describe the feeling out loud",
                "Watch a comfort show (cartoon, cooking, reality TV)",
                "Scroll oddly satisfying videos (slime, ASMR, paint mixing)",
                "Doodle on your skin with a pen or marker",
                "Chew something strong (ice, mint gum, lemon)",
                "Play with your dogs (pet them, teach a trick, go for a walk)"
            ],
            color: "#FF6B6B"
        ),
        
        SupportCategory(
            icon: "paintbrush.fill",
            title: "🎨 Hands-On (Engage Your Senses)",
            subtitle: "Physical activities to ground yourself",
            items: [
                "Play a mindless phone game (Tetris, Candy Crush, Wordle)",
                "Paint with your hands or palette knife — no goal, just feel it",
                "Try a weird makeup look or new outfit",
                "Clean your space (one drawer, one surface — not the whole room)",
                "Do a puzzle, LEGO, or simple DIY craft",
                "Bake something easy or aesthetic (boxed mix, toast art, etc.)"
            ],
            color: "#4ECDC4"
        ),
        
        SupportCategory(
            icon: "brain.head.profile",
            title: "🧠 Occupy Your Brain",
            subtitle: "Mental distractions and redirects",
            items: [
                "Watch a YouTube video to learn something (art, storytime, psychology)",
                "Do a 10-minute \"just start\" gym session",
                "Make a playlist that matches your mood exactly",
                "Read Reddit threads (r/askreddit, r/NoStupidQuestions, etc.)",
                "Write 5 \"unhinged\" affirmations in Notes (e.g., \"I am the storm\")"
            ],
            color: "#95E1D3"
        ),
        
        SupportCategory(
            icon: "lightbulb.fill",
            title: "💬 Why These Options Work",
            subtitle: "Understanding the science behind relief",
            items: [
                "🐾 Lay on the floor with your dog + deep breath\n→ Physical touch + calm breathing quiets the panic center of your brain",
                "🎧 Put on a \"nothing matters\" playlist\n→ Gives the \"detached from stress\" feeling without weed",
                "🧊 Cold washcloth on your face or hold ice cubes\n→ Shocks your nervous system back to the present",
                "🎨 5-min messy painting session (no rules)\n→ Releases trapped energy + focuses your mind",
                "💬 Say the thought out loud like a cartoon villain\n→ Makes the thought feel less powerful or real",
                "🕹️ Distract with a low-stakes game or show\n→ Moves the brain out of panic loops into neutral",
                "💪 Do 20 squats / pushups / jumping jacks\n→ Physical intensity interrupts spiraling"
            ],
            color: "#F38181"
        ),
        
        SupportCategory(
            icon: "calendar.badge.checkmark",
            title: "📓 Practice Habits (Long-Term Tools)",
            subtitle: "Build resilience over time",
            items: [
                "✍️ Journal: \"What is this part of me afraid of?\"\n→ Builds awareness + reduces shame",
                "🎨 Schedule daily painting time (even 10 min)\n→ Expressive art lowers cortisol",
                "🧠 One guided meditation per day (RAIN / self-compassion)\n→ Helps you face thoughts instead of escaping them",
                "📓 Track triggers (time, what happened, after-effects)\n→ Helps identify patterns + regain control",
                "💬 Create a \"conflict plan\" (self-soothing script)\n→ Builds trust in your ability to handle conflict",
                "🧍‍♀️ Use the gym as an emotional outlet\n→ Converts emotional pressure into physical strength",
                "🟪 5-4-3-2-1 grounding exercise\n→ Sensory engagement pulls you out of spiraling"
            ],
            color: "#AA96DA"
        )
    ]
}
